#!/bin/bash

#1. remove old work directory if existed
rm -rf ./teoria

#2. clone teoria
git clone https://github.com/saebekassebil/teoria.git
#cp -r teoria.bak teoria

#3. install teoria
cd teoria # CurrentDir: ./teoria
npm install
npm run test
npm install recast
npm install minimist
npm install -g uglify-js
npm install browserify --save

#4. modify testing suite in order to run test on bundle file
npm run bundle
for file in `ls ./test`
do
  sed -i "" "s/teoria = require('..\/'/teoria = require('..\/teoria'/" ./test/$file
done
npm run test

#5. parse bundle file, count total number of functions,
#   and add profiling statement for every function
rm -rf ./parse
cp -r ../parse .
cd ./parse # CurrentDir: ./teoria/parse
cp ../teoria.js .
node runParse --filename='teoria'
cp ./teoria-tracked.js ../

#6. run test on profiling bundle file,
#   record executed functions in file 'functions-exec'
cd .. #CurrentDir: ./teoria
for file in `ls ./test`
do
  sed -i "" "s/teoria = require('..\/teoria'/teoria = require('..\/teoria-tracked'/" ./test/$file
done
npm run test > ./parse/profiling-result
cat ./parse/profiling-result | grep 'function_[0-9]*_[0-9]*' | sed "s/.*\(function\_[0-9]*\_[0-9]*\).*/\1/g" | sort -n | uniq > ./parse/functions-exec

#7 remove unused functions based on the result of 'functions-exec'
#  and generate optimized bundle file
cd ./parse #CurrentDir: ./easystarjs/parse
cd ./parse #CurrentDir: ./teoria/parse
node runReadUFF
node runRemove --filename='teoria'
cp teoria-optimized.js ../

#8 run test on optimized bundle file
cd .. #CurrentDir: ./teoria
for file in `ls ./test`
do
  sed -i "" "s/teoria = require('..\/teoria-tracked'/teoria = require('..\/teoria-optimized'/" ./test/$file
done
npm run test

#9 minify files
uglifyjs --compress --mangle -- teoria.js > teoria-min.js
uglifyjs --compress --mangle -- teoria-tracked.js > teoria-tracked-min.js
uglifyjs --compress --mangle -- teoria-optimized.js > teoria-optimized-min.js

#10 result
functions_in_bundle=$(wc -l ./parse/functions-original | awk '{print $1}')
functions_executed=$(wc -l ./parse/functions-exec | awk '{print $1}')
functions_deleted=$(($functions_in_bundle-$functions_executed))
file_size=$(wc -c teoria-min.js | awk '{print $1}')
optimized_file_size=$(wc -c teoria-optimized-min.js | awk '{print $1}')
echo "------optimize teoria result------"
echo "functions in bundle: "$functions_in_bundle
echo "functions executed: "$functions_executed
echo "functions deleted: "$functions_deleted
echo "bundle file size: "$file_size
echo "optimized bundle file size: "$optimized_file_size
echo "optimized ratio: "$((($file_size-$optimized_file_size)*100/$file_size))"%"

