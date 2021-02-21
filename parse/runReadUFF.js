const fs = require('fs')
const totalArr = fs.readFileSync('functions-original').toString().split('\n')
const execArr = fs.readFileSync('functions-exec').toString().split('\n')

const totalSet = new Set(totalArr)
const execSet = new Set(execArr)

const diffSet = Array.from(
  new Set(
    totalArr.concat(execArr).filter((v) => !totalSet.has(v) || !execSet.has(v))
  )
)

diffSet.map((item) => {
  fs.appendFileSync('functions-removed', `${item}\n`, 'utf-8')
})

console.log(
  '******************************    Diff set done    ******************************'
)
