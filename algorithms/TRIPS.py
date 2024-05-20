from indra.sources import trips
import pandas as pd

def name_collapse(statement):
    '''
    Because the statements do not always include the gene or protein name, 
    this function breaks a dictionary of statements into "HGNC|UP|Entrez"

    statement: An Indra statement dictionary
    '''

    HGNC = ""
    UP = ""
    Entrez = ""

    frozen_keys = frozenset(statement.keys())

    if "HGNC" in frozen_keys:
        HGNC = statement["HGNC"]
    if "UP" in frozen_keys:
        UP = statement["UP"]
    if "Entrez" in frozen_keys:
        Entrez = statement["Entrez"]

    return HGNC + "|" + UP + "|" + Entrez

def use_trips(text):
    '''
    Pull the INDRA docker container, and run with:
    docker run -id -p 8080:8080 --entrypoint python labsyspharm/indra /sw/indra/rest_api/api.py

    text: (str) A single string containing the abstract to parse
    '''

    ####################
    ## INPUT CHECKING ##
    ####################

    # Make text a string
    text = str(text)

    ######################
    ## PROCESS ABSTRACT ##
    ######################

    # Run trips
    td = trips.process_text(text = text)

     # Build a list of acceptable database names for genes/proteins
    # https://indra.readthedocs.io/en/latest/modules/statements.html
    # We are not including protein chains, protein families, chemicals,
    # general terms, etc.
    acceptable_dbs = ["HGNC", "UP", "Entrez"]

    # Return relationships if they exist
    if (len(td.statements) > 0):

        # Hold all results
        theResults = []

        # Iterate through statements
        for num in range(len(td.statements)):

            # Pull the first and second statement 
            first_stat = td.statements[num].real_agent_list()[0].db_refs
            try:
                second_stat = td.statements[num].real_agent_list()[1].db_refs
            except IndexError:
                second_stat = td.statements[num].real_agent_list()[0].db_refs

            # Pull the statement entity key sets
            first_keys = frozenset(first_stat.keys())
            second_keys = frozenset(second_stat.keys())

            # Determine whether each key is an acceptable class
            first_acc = any([x in ["HGNC", "UP", "Entrez"] for x in first_keys])
            second_acc = any([x in ["HGNC", "UP", "Entrez"] for x in second_keys])

            if first_acc and second_acc:

                # Append to results only if the first and second key are from acceptable dbs
                theResults.append([name_collapse(first_stat), name_collapse(second_stat), 1, "Indra Trips/Drum"])

        # Make pandas data.frame
        result_df = pd.DataFrame(theResults).rename({0:"Biomolecule1", 1:"Biomolecule2", 2:"Score", 3:"ScoreName"}, axis = 1)
    
        return(result_df)