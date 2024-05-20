import os
import requests
from bs4 import BeautifulSoup
import tarfile
import metapub
import pypdf
import io
import urllib3

# This script contains 3 functions for pulling data from the PubMed database: Clean text, PDFs, and abstracts/titles.

def pull_pubmed_clean(ids, output_directory, tarball_path):

    notfound_count = 0
    found_ids = []

    pmc_list = []
    if tarball_path is None:
        tarball_path = os.path.join(output_directory, "pubmed_tarballs")
        os.mkdir(tarball_path)
    else:
        # Create a list of pre-written PMC names if tarball_path has been pre-specified
        for _, _, files in os.walk(tarball_path):
            # If files are present, we will make a list of what's in there already and then append new files to this directory instead of 
            #   a subfolder of output_dire
            # Else, we will write new files to this directory instead of writing into our output_dir
            if len(files) > 0:
                for file in files:
                    if ".tar.gz" in file and "PMC" in file:
                        pmc_list.append(file.split(".")[0])

    write_path = os.path.join(output_directory, "pubmed_clean")
    os.mkdir(write_path)

    # First find tarballs and download them into an internal directory # Delete them?
    for pmid in ids:
        # Find if the PubMed Article has a corresponding PubMed Central ID and page
        req = requests.get("https://pubmed.ncbi.nlm.nih.gov/" + str(pmid) + "/")
        soup = BeautifulSoup(req.content, 'html.parser')
        pmc_url = soup.find_all("a", class_="id-link", attrs={"data-ga-action":"PMCID"})
        if len(pmc_url) > 0:
            try:
                # Use that PubMedCentral ID to find where the article is stored on FTP
                pmcid = pmc_url[0].get_text().strip()
                if pmcid in pmc_list:
                    # tarball has already been downloaded to the `tarball_path`. Don't re-download. Break from loop to next pmid.
                    break
                link = "https://www.ncbi.nlm.nih.gov/pmc/utils/oa/oa.fcgi?id=" + pmcid
                tgz_url = "https://" + BeautifulSoup(requests.get(link).content, 'html.parser').find("link", attrs={"format":"tgz"}).get("href")[6:]
                response = requests.get(tgz_url, stream=True)
                # Download the tarball from the FTP location
                if response.status_code == 200:
                    filename = os.path.join(tarball_path, pmcid + ".tar.gz")
                    with open(filename, 'wb') as f:
                        f.write(response.raw.read())
                else:
                    notfound_count += 1
            except AttributeError:
                notfound_count += 1
            except TimeoutError:
                notfound_count += 1
            except urllib3.exceptions.ProtocolError:
                notfound_count += 1


    # Now grab the text from the tarballs
    for _, _, files in os.walk(tarball_path):
        for file in files:
            # Grab .nxml file in each tarball
            if ".tar.gz" in file:
                try:
                    tar = tarfile.open(os.path.join(tarball_path, file))
                    for member in tar.getmembers():
                        # Each tarball should have one .nxml file that contains the full article
                        if ".nxml" in member.name:
                            f = tar.extractfile(member)
                            content = f.read()  
                            # Create text file from xml (html parsed with Beautiful Soup)
                            soup = BeautifulSoup(content, "html.parser")
                            # Remove tables and certain math objects from xml
                            for x in soup.find_all('table-wrap'):
                                x.decompose()
                            for x in soup.find_all('mml:annotation'):
                                x.decompose()
                            pmid = soup.find("article-id", attrs={"pub-id-type":"pmid"}).get_text()
                            file_name = os.path.join(write_path, str(pmid) + ".txt")
                            with open(file_name, "w") as f:
                                for p in soup.find_all("p", recurisve=False):
                                    f.write(p.get_text())
                            # success --> append id (Integer type) to found-list
                            found_ids.append(pmid.strip())
                            #.nxml found and txt written, go to next tarball
                            tar.close()
                            break                         
                except tarfile.ReadError:
                    # Some cases where a tarball downloaded, but it's empty ??
                    notfound_count += 1
    
    return(found_ids)

def pull_pubmed_pdfs(ids, output_directory):

    notfound_count = 0
    write_path = os.path.join(output_directory, "pubmed_pdfs")
    os.mkdir(write_path)
    found_ids = []

    # Iterate through list and try to scan the pdf and save to a folder
    for pmid in ids:
        try:
            src = metapub.FindIt(str(pmid))
            req = requests.get(src.url)
            pdf = io.BytesIO(req.content)
            reader = pypdf.PdfReader(pdf)
            filename = os.path.join(write_path, str(pmid) + ".txt")
            with open(filename, 'w') as f:
                for i in range(len(reader.pages)):
                    f.write(" ".join(reader.pages[i].extract_text().split("\n"))) 
            # success --> append id (Integer type) to found-list
            found_ids.append(pmid)

        except requests.exceptions.MissingSchema:
            #print("Invalid URL for article {}".format(pmid))
            notfound_count += 1
        except pypdf._utils.PdfStreamError:
            #print("PDF Stream Error with article {}".format(pmid))
            notfound_count += 1
        except pypdf.generic._data_structures.PdfReadError:
            #print("PDF Read Error with article {}".format(pmid))
            notfound_count += 1
        except metapub.exceptions.InvalidPMID:
            #print("PubMed invalid article error for article {}".format(pmid))
            notfound_count += 1
        except AttributeError:
            #print("Attribute Error with article {}".format(pmid))
            notfound_count += 1
        except TypeError:
            #print("Type Error with article {}".format(pmid))
            notfound_count += 1
        except UnicodeEncodeError:
            #print("Encoding Error with article {}".format(pmid))
            notfound_count += 1
    return(found_ids)

def pull_pubmed_abstracts(ids, output_directory, abstract_include_title):

    write_path = os.path.join(output_directory, "pubmed_abstracts")
    os.mkdir(write_path)
    found_ids = []
    notfound_count = 0

    for pmid in ids:
        url = "https://pubmed.ncbi.nlm.nih.gov/" + str(pmid) + "/"
        req = requests.get(url)
        soup = BeautifulSoup(req.content, "html.parser")
        try:
            abstract = soup.find(id="eng-abstract").get_text().strip()
            with open(os.path.join(write_path, str(pmid) + ".txt"), "w")as f:
                if abstract_include_title:
                    f.write(soup.find("meta", {"name":"citation_title"})['content'])
                    f.write(". ")
                f.write(abstract)
            # success --> append id (Integer type) to found-list
            found_ids.append(pmid)
        except AttributeError:
            try:
                #print("{} for article {}".format(soup.find(class_="empty-abstract").get_text(), pmid))
                notfound_count += 1
            except AttributeError:
                #print("Error with article {}".format(pmid))
                notfound_count += 1
        
    return(found_ids)
