#!/bin/bash

#1. remove old work directory if existed
rm -rf ./underscore.string

#2. clone underscore.string
git clone https://github.com/esamattis/underscore.string.git
#cp -r underscore.string.bak underscore.string

#3. install underscore.string
cd underscore.string # CurrentDir: ./underscore.string
npm install
npm run test:unit
npm install recast
npm install minimist
npm install -g uglify-js

#4. modify testing suite in order to run test on bundle file
npm run build
for file in `ls ./tests`
do
 var=$(echo $file | awk -F'.' '{print $1}')
 sed -i "" "s/var ${var} = require('..\/${var}/var { ${var} } = require('..\/dist\/underscore.string/" ./tests/$file
done
npm run test:unit

#5. parse bundle file, count total number of functions,
#   and add profiling statement for every function
rm -rf ./parse
cp -r ../parse .
cd ./parse # CurrentDir: ./underscore.string/parse
cp ../dist/underscore.string.js .
node runParse --filename='underscore.string'
cp ./underscore.string-tracked.js ../dist

#6. run test on profiling bundle file,
#   record executed functions in file 'functions-exec'
cd .. #CurrentDir: ./underscore.string
for file in `ls ./tests`
do
 var=$(echo $file | awk -F'.' '{print $1}')
 sed -i "" "s/require('..\/dist\/underscore.string/require('..\/dist\/underscore.string-tracked/" ./tests/$file
done
npm run test:unit > ./parse/profiling-result
cat ./parse/profiling-result | grep 'function_[0-9]*_[0-9]*' | sed "s/.*\(function\_[0-9]*\_[0-9]*\).*/\1/g" | sort -n | uniq > ./parse/functions-exec

#7 remove unused functions based on the result of 'functions-exec'
#  and generate optimized bundle file
cd ./parse #CurrentDir: ./underscore.string/parse
node runReadUFF
node runRemove --filename='underscore.string'
cp underscore.string-optimized.js ../dist

#8 run test on optimized bundle file
cd .. #CurrentDir: ./underscore.string
for file in `ls ./tests`
do
 var=$(echo $file | awk -F'.' '{print $1}')
 sed -i "" "s/require('..\/dist\/underscore.string-tracked/require('..\/dist\/underscore.string-optimized/" ./tests/$file
done
npm run test:unit

#9 minify files
cd ./parse #CurrentDir: ./underscore.string/parse
uglifyjs --compress --mangle -- underscore.string-tracked.js > underscore.string-tracked-min.js
uglifyjs --compress --mangle -- underscore.string-optimized.js > underscore.string-optimized-min.js

#10 result
cd .. #CurrentDir: ./underscore.string
functions_in_bundle=$(wc -l ./parse/functions-original | awk '{print $1}')
functions_executed=$(wc -l ./parse/functions-exec | awk '{print $1}')
functions_deleted=$(($functions_in_bundle-$functions_executed))
file_size=$(wc -c ./dist/underscore.string.min.js | awk '{print $1}')
optimized_file_size=$(wc -c ./parse/underscore.string-optimized-min.js | awk '{print $1}')
echo "------optimize underscore.string result------"
echo "functions in bundle: "$functions_in_bundle
echo "functions executed: "$functions_executed
echo "functions deleted: "$functions_deleted
echo "bundle file size: "$file_size
echo "optimized bundle file size: "$optimized_file_size
echo "optimized ratio: "$((($file_size-$optimized_file_size)*100/$file_size))"%"

