#!/bin/bash

#1. remove old work directory if existed
rm -rf ./easystarjs

#2. clone easystart
git clone https://github.com/prettymuchbryce/easystarjs.git
#cp -r easystarjs.bak easystarjs

#3. install easystart
cd easystarjs # CurrentDir: ./easystarjs
npm install
npm run build:production
npm run test
npm install recast
npm install minimist
npm install -g uglify-js

#4. modify testing suite in order to run test on bundle file
sed -i '' 's/..\/src\/easystar/..\/bin\/easystar-0.4.4/' ./test/easystartest.js
echo "module.exports = EasyStar;" >> ./bin/easystar-0.4.4.js
npm run test

#5. parse bundle file, count total number of functions,
#   and add profiling statement for every function
rm -rf ./parse
cp -r ../parse .
cd ./parse # CurrentDir: ./easystarjs/parse
cp ../bin/easystar-0.4.4.js .
node runParse --filename='easystar-0.4.4'
cp ./easystar-0.4.4-tracked.js ../bin/

#6. run test on profiling bundle file,
#   record executed functions in file 'functions-exec'
cd .. #CurrentDir: ./easystarjs
sed -i '' 's/..\/bin\/easystar-0.4.4/..\/bin\/easystar-0.4.4-tracked/' ./test/easystartest.js
npm run test > ./parse/profiling-result
cat ./parse/profiling-result | grep 'function_[0-9]*_[0-9]*' | sed "s/.*\(function\_[0-9]*\_[0-9]*\).*/\1/g" | sort -n | uniq > ./parse/functions-exec

#7 remove unused functions based on the result of 'functions-exec'
#  and generate optimized bundle file
cd ./parse #CurrentDir: ./easystarjs/parse
node runReadUFF
node runRemove --filename='easystar-0.4.4'
cp easystar-0.4.4-optimized.js ../bin/

#8 run test on optimized bundle file
cd .. #CurrentDir: ./easystarjs
sed -i '' 's/..\/bin\/easystar-0.4.4-tracked/..\/bin\/easystar-0.4.4-optimized/' ./test/easystartest.js
npm run test

#9 minify files
cd ./parse #CurrentDir: ./easystarjs/parse
uglifyjs --compress --mangle -- easystar-0.4.4-tracked.js > easystar-0.4.4-tracked-min.js
uglifyjs --compress --mangle -- easystar-0.4.4-optimized.js > easystar-0.4.4-optimized-min.js

#10 result
cd .. #CurrentDir: ./easystarjs
functions_in_bundle=$(wc -l ./parse/functions-original | awk '{print $1}')
functions_executed=$(wc -l ./parse/functions-exec | awk '{print $1}')
functions_deleted=$(($functions_in_bundle-$functions_executed))
file_size=$(wc -c ./bin/easystar-0.4.4.min.js | awk '{print $1}')
optimized_file_size=$(wc -c ./parse/easystar-0.4.4-optimized-min.js | awk '{print $1}')
echo "------optimize easystarjs result------"
echo "functions in bundle: "$functions_in_bundle
echo "functions executed: "$functions_executed
echo "functions deleted: "$functions_deleted
echo "bundle file size: "$file_size
echo "optimized bundle file size: "$optimized_file_size
echo "optimized ratio: "$((($file_size-$optimized_file_size)*100/$file_size))"%"

