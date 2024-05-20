# Adapted from: https://github.com/ssr01357/BertSRC

import pandas as pd
from sklearn.preprocessing import LabelEncoder
from transformers import BertTokenizer, TrainingArguments, Trainer

import torch
from torch.nn import BCEWithLogitsLoss, CrossEntropyLoss, Dropout, Linear, MSELoss, Tanh
from transformers import BertModel, BertPreTrainedModel
from transformers.modeling_outputs import SequenceClassifierOutput

from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    precision_recall_fscore_support,
)

CLASSES = ["0", "1"]

def compute_metrics(pred):
    """compute metrics for huggingface transformers trainer
    """
    labels = pred.label_ids
    preds = pred.predictions.argmax(-1)
    precision, recall, f1, _ = precision_recall_fscore_support(
        labels, preds, average="macro"
    )
    acc = accuracy_score(labels, preds)
    print(classification_report(labels, preds, digits=3, target_names=CLASSES))
    return {"accuracy": acc, "precision": precision, "recall": recall, "f1": f1}

def preprocess_data(df, tokenizer, x_col, y_col, e1_col, e2_col):
    """preprocesse data

    Args:
        df: source dataframe data
        tokenizer: tokenizer
        x_col: sentence column name
        y_col: label column name
        e1_col: first entity column name
        e2_col: second entity column name

    Returns:
        SrcDataset: SrcDataset
    """
    # 2-Masted-senteces input format
    x1 = df.apply(lambda x: x[x_col].replace(x[e1_col], "[MASK]"), axis=1).tolist()
    x2 = df.apply(lambda x: x[x_col].replace(x[e2_col], "[MASK]"), axis=1).tolist()

    label_encoder = LabelEncoder()
    y = torch.tensor(label_encoder.fit_transform(df[y_col]), dtype=torch.long)

    tokenized_x = tokenizer(x1, x2, return_tensors="pt", padding='max_length', truncation=True, max_length=512)

    dataset = SrcDataset(tokenized_x, y)
    return dataset

class SrcDataset(torch.utils.data.Dataset):
    """Dataset class for BertSRC
    """
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):
        item = {key: val[idx] for key, val in self.encodings.items()}
        item["labels"] = self.labels[idx]
        return item

    def __len__(self):
        return len(self.labels)


class BertSrcClassifier(BertPreTrainedModel):
    """BertSRC Classifier
    """
    def __init__(self, config, mask_token_id: int, num_token_layer: int = 2):
        super().__init__(config)
        self.mask_token_id = mask_token_id
        self.n_output_layer = num_token_layer
        self.num_labels = config.num_labels
        self.config = config

        self.bert = BertModel(config)
        self.dense = Linear(config.hidden_size * num_token_layer, config.hidden_size)
        self.activation = Tanh()
        self.dropout = Dropout(p = 0.5) # Originally 0.1
        self.classifier = Linear(config.hidden_size, config.num_labels)

        self.post_init()

    def forward(
        self,
        input_ids: torch.Tensor = None,
        attention_mask: torch.Tensor = None,
        token_type_ids: torch.Tensor = None,
        position_ids: torch.Tensor = None,
        head_mask: torch.Tensor = None,
        inputs_embeds: torch.Tensor = None,
        labels: torch.Tensor = None,
        output_attentions: bool = None,
        output_hidden_states: bool = None,
        return_dict: bool = None,
    ):
        return_dict = (
            return_dict if return_dict is not None else self.config.use_return_dict
        )

        outputs = self.bert(
            input_ids,
            attention_mask=attention_mask,
            token_type_ids=token_type_ids,
            position_ids=position_ids,
            head_mask=head_mask,
            inputs_embeds=inputs_embeds,
            output_attentions=output_attentions,
            output_hidden_states=output_hidden_states,
            return_dict=return_dict,
        )

        assert 1 <= self.n_output_layer <= 3
        if self.n_output_layer == 1:
            output = outputs[0][0]
        else:
            check = input_ids == self.mask_token_id
            if self.n_output_layer == 3:
                check[:, 0] = True
            output = torch.reshape(
                outputs[0][check], (-1, self.n_output_layer * self.config.hidden_size)
            )

        output = self.dense(output)
        output = self.activation(output)
        output = self.dropout(output)
        logits = self.classifier(output)

        loss = None
        if labels is not None:
            if self.config.problem_type is None:
                if self.num_labels == 1:
                    self.config.problem_type = "regression"
                elif self.num_labels > 1 and (
                    labels.dtype == torch.long or labels.dtype == torch.int
                ):
                    self.config.problem_type = "single_label_classification"
                else:
                    self.config.problem_type = "multi_label_classification"

            if self.config.problem_type == "regression":
                loss_fct = MSELoss()
                if self.num_labels == 1:
                    loss = loss_fct(logits.squeeze(), labels.squeeze())
                else:
                    loss = loss_fct(logits, labels)
            elif self.config.problem_type == "single_label_classification":
                loss_fct = CrossEntropyLoss()
                loss = loss_fct(logits.view(-1, self.num_labels), labels.view(-1))
            elif self.config.problem_type == "multi_label_classification":
                loss_fct = BCEWithLogitsLoss()
                loss = loss_fct(logits, labels)
        if not return_dict:
            output = (logits,) + outputs[2:]
            return ((loss,) + output) if loss is not None else output

        return SequenceClassifierOutput(
            loss=loss,
            logits=logits,
            hidden_states=outputs.hidden_states,
            attentions=outputs.attentions,
        )
    
    train = pd.read_table("path/data/benchmark1/su_training_sentences1.txt", encoding="utf-8")
    validation = pd.read_table("path/data/benchmark1/su_training_sentences2.txt", encoding="utf-8")

    tokenizer = BertTokenizer.from_pretrained(
        "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext" # PubMedBERT: "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext"
    )
    model = BertSrcClassifier.from_pretrained(
        "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext", # PubMedBERT: "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext"
        num_labels=len(CLASSES),
        mask_token_id=tokenizer.mask_token_id,
    )

train_dataset = preprocess_data(train, tokenizer, x_col="Sentence", y_col="Label", e1_col="Term1", e2_col = "Term2")
validation_dataset = preprocess_data(validation, tokenizer, x_col = "Sentence", y_col = "Label", e1_col = "Term1", e2_col = "Term2")

training_args = TrainingArguments(
    output_dir="./checkpoints",
    logging_dir="./logs",
    evaluation_strategy="epoch",
    save_strategy="epoch",
    logging_strategy="epoch",
    num_train_epochs=10, # Originally 10
    learning_rate=5e-5, # Originally 5e-5
    per_device_train_batch_size=16,
    per_device_eval_batch_size=64,
    warmup_ratio=0.1,
    weight_decay=0.01,
    adam_beta1=0.9,
    adam_beta2=0.999,
    adam_epsilon=1e-8,
    max_grad_norm=1,
    lr_scheduler_type="linear",
    load_best_model_at_end=True,
    metric_for_best_model="f1",
    seed=42,
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=validation_dataset,
    compute_metrics=compute_metrics,
)

trainer.train()
trainer.save_model("./checkpoints/best_model") 