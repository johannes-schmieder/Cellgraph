# Cellgraph
Flexible Stata command to create descriptive figures based on collapsing the data to cells  


curl -s https://api.github.com/repos/johannes-schmieder/Cellgraph/contents/ | jq '.[] | .name'


wget -r -np -nH --cut-dirs=3 -R "index.html*" https://raw.githubusercontent.com/johannes-schmieder/Cellgraph/master/


net install estout, replace from(https://raw.githubusercontent.com/benjann/estout/master/)
net install cellgraph, replace from(https://raw.githubusercontent.com/johannes-schmieder/Cellgraph/master/)


# Define the base URLs
api_url="https://api.github.com/repos/johannes-schmieder/Cellgraph/contents/"
base_url="https://raw.githubusercontent.com/johannes-schmieder/Cellgraph/master/"

# Get a list of files from the GitHub API and download each one
curl -s $api_url | jq -r '.[] | .name' | while read -r file; do
    echo "Downloading $file..."
    wget "${base_url}${file}"
done

# Define the base URLs
api_url="https://api.github.com/repos/benjann/coefplot/contents/"
base_url="https://raw.githubusercontent.com/benjann/coefplot/master/"

# Get a list of files from the GitHub API and download each one
curl -s $api_url | jq -r '.[] | .name' | while read -r file; do
    echo "Downloading $file..."
    wget "${base_url}${file}"
done