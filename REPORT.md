### 1. Introduction

I've read the [paper](http://bergel.eu/MyPapers/Cefe18a-Slimming.pdf)  that introduces an appoach to slim JavaScript libraries. it mentioned that a JS lib may require other libraries, Some functions in the dependent libraries may be unused in this lib, so the paper gave us a dynamic approach to identify and remove UFFs from JavaScript Bundles. 

Empirically, I agree with this opinion. Since this is a technical task, I decided to implement this approach by myself and verify the optimization effect mentioned in the paper.

First, I would like to do some simplification: 

+ Since this experimental task would not run in the production environment, and test coverage of the libs mentioned in the paper is greater than 85%, I just use tests shipped in these libs to identify and remove UFFs. So I just `empty` all UFFs body without using lazy load mechanism.
+ For the reason that each lib has its own project structure and testing suite, I need to figure out how to genarate bundle.js and modify testing suite to make the test run successfully on the bundle file one by one, it can be a time-consuming part. Furtheremore, some libs are too outdated that can not run test successfully on my DEV environment. So I just verify 5 libs(@lastest version) in the table:  `easystarjs`, `geojsonhint`, `teoria`, `underscore-string`, `unified`.



### 2. Development

In order to identify these unused functions and remove them, I need to firstly find a way to pick up all functions in bundle.js.  Parsing the file to an AST tree and analyze each node in the tree is the most effective and accurate way. With the help of JS lib `recast`, I can get the AST tree of bundle.js. While traversing the AST tree to find the two types of function patterns mentioned in the paper: Function Declaration and Function Expression, I write a recursive method which tackles 26 types of node to find the two function patterns accurately.

In addition, I write a shell script for each library that can do all the slimming work automatically and print the result of the slimming effect in the end.

I name the program *`serendipity`* and push it with more description about this program in detail on github [serendipity](https://github.com/SandZn/serendipity). You can review it and run it easily if you are interested.



### 3. Result

|        lib        | functions in bundle file | functions executed | functions removed | bundle file size | optimized  bundle file size | optimized ratio % |
| :---------------: | :----------------------: | :----------------: | :---------------: | :--------------: | :-------------------------: | :---------------: |
|      teoria       |           119            |         99         |        20         |      19060       |            17687            |         7         |
|    geojsonhint    |           115            |         65         |        50         |      23165       |            17851            |        22         |
|      unified      |           120            |         76         |        44         |      12988       |            9298             |        28         |
|    easystarjs     |            80            |         42         |        38         |      10024       |            6777             |        32         |
| underscore.string |           170            |        163         |         7         |      32284       |            21120            |        34         |

### 4. Analysis and conclution

As we can see from the table above, there are some differences between results of my approach and that in the paper.

+ The reason of differences on Column **Functions in bundle file** is that I run the lastest version for each lib but the paper used previous version, some of them are outdated. However, I use the parsing tool provided in the paper to analyze the lastest version lib, and get a same result as the table above shows. So the result of this column is correct.
+ Funcitons executed and removed are different from the paper. This is also because of the differences in version. Different version has different test cases, different cases generate different **Functions executed** result . It affects the number of **Functions removed**, and **optimized bundle file size** further. So as we can see from my experiment result, the approach introduced by the paper is valid. Four fifth of the target libs size can be reduced by 20%-30%. 
+ In addition, I checked the validity of my experiment result. Firstly, I replace each UFF body by an invalid statement which can definitely throw error and terminate the program if it is called. Then I ran test process again and all cases passed. Secondly, I replace some of non-UFF body by the same invalid statement and the test process failed as expected. So I ensure the validity of my experiment result.

### 5. My thought

The slimming method in the paper is a dynamic analysis. It needs a great coverage in testing and usage scenario. But I suppose most of the work can be done by static analysis. If we have a way to obtain callgraphs of all functions in bundle file, we can find out the unused function in dependant libraries. For example, we want to slim lib A, and lib A is depend on lib B. Lib A defines three functions: Func A1, A2, A3. Lib B defines 5 functions: Func B1, B2, B3, B4, B5. Through static analysis, we get a callgraph: 

```
A1 invokes B1, B2; 
A2 invokes B3; 
A3 invokes B4.
```

B5 will never be invoked by lib A.  So we can remove B5 safely. This optimized result can be obtained without dynamic analysis. It is just a simple description, there can be more complicated in reality situation, I would like to do some more research on it.