#!/usr/bin/env node
const args = require('minimist')(process.argv.slice(2))
const { filename } = args

const recast = require('recast')
const fs = require('fs')
const { removeUFFFunctions } = require('./utils')

const sourceFileString = fs.readFileSync(`${filename}.js`, 'utf-8')
const ast = recast.parse(sourceFileString)
const astBody = ast.program.body

removeUFFFunctions(astBody)

const targetFileString = recast.print(ast).code
fs.writeFileSync(`${filename}-optimized.js`, targetFileString, 'utf-8')

console.log(
  '******************************    Remove(Empty) done    ******************************'
)
