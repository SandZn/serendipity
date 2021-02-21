#!/bin/bash

#1. remove old work directory if existed
rm -rf ./unified

#2. clone unified
git clone https://github.com/unifiedjs/unified.git
#cp -r unified.bak unified

#3. install unified
cd unified # CurrentDir: ./unified
npm install
npm run test-coverage
npm install recast
npm install minimist
npm install -g uglify-js

#4. parse bundle file, count total number of functions,
#   and add profiling statement for every function
npm run build
rm -rf ./parse
cp -r ../parse .
cd ./parse # CurrentDir: ./unified/parse
cp ../unified.js .
node runParse --filename='unified'

#5. modify testing suite and run test on profiling bundle file,
#   record executed functions in file 'functions-exec'
cd .. #CurrentDir: ./unified
cp index.js index.js.bak
cp ./parse/unified-tracked.js index.js
npm run test-coverage > ./parse/profiling-result
cat ./parse/profiling-result | grep 'function_[0-9]*_[0-9]*' | sed "s/.*\(function\_[0-9]*\_[0-9]*\).*/\1/g" | sort -n | uniq > ./parse/functions-exec

#6 remove unused functions based on the result of 'functions-exec'
#  and generate optimized bundle file
cd ./parse #CurrentDir: ./unified/parse
node runReadUFF
node runRemove --filename='unified'

#7 run test on optimized bundle file
cd .. #CurrentDir: ./unified
cp ./parse/unified-optimized.js index.js
npm run test-coverage

#9 minify files
cd ./parse #CurrentDir: ./unified/parse
uglifyjs --compress --mangle -- unified-tracked.js > unified-tracked-min.js
uglifyjs --compress --mangle -- unified-optimized.js > unified-optimized-min.js

#10 result
cd .. #CurrentDir: ./unified
functions_in_bundle=$(wc -l ./parse/functions-original | awk '{print $1}')
functions_executed=$(wc -l ./parse/functions-exec | awk '{print $1}')
functions_deleted=$(($functions_in_bundle-$functions_executed))
file_size=$(wc -c unified.min.js | awk '{print $1}')
optimized_file_size=$(wc -c ./parse/unified-optimized-min.js | awk '{print $1}')
echo "------optimize unified result------"
echo "functions in bundle: "$functions_in_bundle
echo "functions executed: "$functions_executed
echo "functions deleted: "$functions_deleted
echo "bundle file size: "$file_size
echo "optimized bundle file size: "$optimized_file_size
echo "optimized ratio: "$((($file_size-$optimized_file_size)*100/$file_size))"%"

