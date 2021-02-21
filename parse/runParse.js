#!/usr/bin/env node
const args = require('minimist')(process.argv.slice(2))
const { filename } = args

const recast = require('recast')
const fs = require('fs')
const { recordAllFunctions } = require('./utils')

const sourceFileString = fs.readFileSync(`${filename}.js`, 'utf-8')
const ast = recast.parse(sourceFileString)
const astBody = ast.program.body

// empty file
fs.writeFileSync('functions-original', '', 'utf-8')
fs.writeFileSync(`${filename}-tracked.js`, '', 'utf-8')

// record all functions
recordAllFunctions(astBody)

const targetFileString = recast.print(ast).code
fs.writeFileSync(`${filename}-tracked.js`, targetFileString, 'utf-8')

console.log(
  '******************************    Track done    ******************************'
)
