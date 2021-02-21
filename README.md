# 1. Serendipity

Serendipity is an experiment tool which implements the method introduced by [the paper](http://bergel.eu/MyPapers/Cefe18a-Slimming.pdf) 

>Slimming javascript applications: An approach for removing unused functions from javascript libraries

to verify its optimization effect. The main verification steps for each JavaScript library is the same, like counting total functions, add profiling info, identifying and removing unused functions. So I extract them into JS functions to make them reusable. Except for these common parts, each library has its own project structure and testing suite, so I need to figure out how to generate bundle.js and modify testing suite to make the test run successfully on the bundle file for the libraries one by one, and this is an intricate part of the experiment. I have finished adapting 5 JavaScript libraries up to now, and wrote shell scripts for each library, If you want to check by yourself, all you have to do is choosing which library you'd like to verify and run the related shell script.

# 2. Dev environment

I wrote Serendipity on my Macbook, and it can run successfully for sure on the Env below:

>MacOS 11.2.1
>
>node -v 10.23.3

# 3. Directory introduction

1. **parse**: The directory which includes some JS file I wrote to do the main operations:

   1. Convert the specified bundle file into AST 
   2. Traverse and parse the AST to find out all the Function Declaration and Function Expression in bundle
   3. Add profiling statement for each function in AST
   4. Remove unused functions from AST base on the result of profiling info
   5. Convert AST back into an JS file, which called -optimized.js

2. **runXXX.sh**: The shell scirpt for running experiment for XXX library. You can run it and it will do all the slimming work for the XXX library and print the result of the slimming effect in the end.

   ```
   runUnderscoreString.sh
   runGeojsonhint.sh
   runEasystar.sh
   runUnified.sh
   runTeoria.sh
   ```

# 4. Main steps

each shell script will do the operations below:

```
1. git clone the specified library from github
2. run the test to make sure all testing cases can be passed before our optimization
3. generate bundle file and modify the testing suite to make the test run on the bundle file
4. run the test on bundle file
5. use the JS functions I wrote in the directory `parse` to parse all the functions in bundle file and add a profiling statement for each one, generating a bundle-tracked file
6. modify the testing suite to make the test run on the bundle-tracked file
7. run the test on bundle-tracked file and get the profiling result(which has the information of all functions executed in the test)
8. slim the bundle file by `empting` the unused functions from that based on the profiling result, generating a bundle-optimized file
9. modify the testing suite to make the test run on the bundle-optimized file, passing all cases as expected
10. minify the bundle file and bundle-optimized file
11. print the result, include: total functions, executed functions, deleted functions, original bundle file size(after minify), bundle-optimized file size and the optimized ratio, like below:
	------optimize geojsonhint result------
  functions in bundle: 115
  functions executed: 65
  functions deleted: 50
  bundle file size: 23165
  optimized bundle file size: 17851
  optimized ratio: 22%
```

*NOTICE: Sed on MacOS is different from Linux, if you run the script on Linux, please replace the parameters of `sed -i ''`by `sed -i`*

# 5 result

```
------optimize underscore.string result------
functions in bundle: 170
functions executed: 163
functions deleted: 7
bundle file size: 32284
optimized bundle file size: 21120
optimized ratio: 34%

------optimize geojsonhint result------
functions in bundle: 115
functions executed: 65
functions deleted: 50
bundle file size: 23165
optimized bundle file size: 17851
optimized ratio: 22%

------optimize unified result------
functions in bundle: 120
functions executed: 76
functions deleted: 44
bundle file size: 12988
optimized bundle file size: 9298
optimized ratio: 28%

  ------optimize teoria result------
functions in bundle: 119
functions executed: 99
functions deleted: 20
bundle file size: 19060
optimized bundle file size: 17687
optimized ratio: 7%

------optimize easystarjs result------
functions in bundle: 80
functions executed: 42
functions deleted: 38
bundle file size: 10024
optimized bundle file size: 6777
optimized ratio: 32%
```

