#!/bin/bash

#1. remove old work directory if existed
rm -rf ./geojsonhint

#2. clone geojsonhint
git clone https://github.com/mapbox/geojsonhint.git
#cp -r geojsonhint.bak geojsonhint

#3. install geojsonhint
cd geojsonhint # CurrentDir: ./geojsonhint
npm install
npm run test
npm install recast
npm install minimist
npm install -g uglify-js

#4. modify testing suite in order to run test on bundle file
npm run prepublish
sed -i "" "s/eslint \. && //" package.json
sed -i "" "s/geojsonhint = require('..\/'/geojsonhint = require('..\/geojsonhint'/" ./test/hint.test.js
npm run test

#5. parse bundle file, count total number of functions,
#   and add profiling statement for every function
rm -rf ./parse
cp -r ../parse .
cd ./parse # CurrentDir: ./geojsonhint/parse
cp ../geojsonhint.js .
node runParse --filename='geojsonhint'
cp ./geojsonhint-tracked.js ../

#6. run test on profiling bundle file,
#   record executed functions in file 'functions-exec'
cd .. #CurrentDir: ./geojsonhint
sed -i "" "s/geojsonhint = require('..\/geojsonhint'/geojsonhint = require('..\/geojsonhint-tracked'/" ./test/hint.test.js
echo "Output has been redirected for this moment, I'm still running, wait please:)"
npm run test > ./parse/profiling-result
cat ./parse/profiling-result | grep 'function_[0-9]*_[0-9]*' | sed "s/.*\(function\_[0-9]*\_[0-9]*\).*/\1/g" | sort -n | uniq > ./parse/functions-exec

#7 remove unused functions based on the result of 'functions-exec'
#  and generate optimized bundle file
cd ./parse #CurrentDir: ./geojsonhint/parse
node runReadUFF
node runRemove --filename='geojsonhint'
cp geojsonhint-optimized.js ../

#8 run test on optimized bundle file
cd .. #CurrentDir: ./geojsonhint
sed -i "" "s/geojsonhint = require('..\/geojsonhint-tracked'/geojsonhint = require('..\/geojsonhint-optimized'/" ./test/hint.test.js
npm run test

#9 minify files
uglifyjs --compress --mangle -- geojsonhint.js > geojsonhint-min.js
uglifyjs --compress --mangle -- geojsonhint-tracked.js > geojsonhint-tracked-min.js
uglifyjs --compress --mangle -- geojsonhint-optimized.js > geojsonhint-optimized-min.js

#10 result
functions_in_bundle=$(wc -l ./parse/functions-original | awk '{print $1}')
functions_executed=$(wc -l ./parse/functions-exec | awk '{print $1}')
functions_deleted=$(($functions_in_bundle-$functions_executed))
file_size=$(wc -c geojsonhint-min.js | awk '{print $1}')
optimized_file_size=$(wc -c geojsonhint-optimized-min.js | awk '{print $1}')
echo "------optimize geojsonhint result------"
echo "functions in bundle: "$functions_in_bundle
echo "functions executed: "$functions_executed
echo "functions deleted: "$functions_deleted
echo "bundle file size: "$file_size
echo "optimized bundle file size: "$optimized_file_size
echo "optimized ratio: "$((($file_size-$optimized_file_size)*100/$file_size))"%"

