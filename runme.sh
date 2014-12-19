
time perl fetch.pl

rm -rf Result

mkdir -p Result

find Cache  -mindepth 3  -type f -exec cp -v '{}' Result  \;


## sudo pip install pyexcelerator
perl parse.pl

# libreoffice Result/sheet.xls


