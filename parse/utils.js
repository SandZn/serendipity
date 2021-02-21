const recast = require('recast')
const fs = require('fs')

let index = 0

function logFunctionId(node) {
  const id = `${node.loc.start.line}_${node.loc.start.column}`
  fs.appendFileSync('functions-original', `function_${id}\n`, 'utf-8')
  console.log(`function_${id}`)
}

function removeUFF(node, id) {
  const insertString = `lyx`
  const insertAst = recast.parse(insertString).program.body[0]
  node.body.body = []
  node.body.body.unshift(insertAst)
}

function recordFunction(node, id) {
  const insertString = `console.log("${id} has been called");`
  const insertAst = recast.parse(insertString).program.body[0]
  node.body.body.unshift(insertAst)
}

function forRecordCycle(nodeArr) {
  const len = nodeArr.length
  for (let i = 0; i < len; i++) {
    recordAllFunctions(nodeArr[i])
  }
}

function forRemoveCycle(nodeArr) {
  const len = nodeArr.length
  for (let i = 0; i < len; i++) {
    removeUFFFunctions(nodeArr[i])
  }
}

function recordAllFunctions(node) {
  recast.visit(node, {
    // 1
    visitFunctionDeclaration: function ({ value }) {
      console.log('visitFunctionDeclaration:', index++)
      const id = `function_${value.loc.start.line}_${value.loc.start.column}`
      recordFunction(value, id)
      logFunctionId(value)
      recordAllFunctions(value.body)
      return false
    },
    // 2
    visitFunctionExpression: function ({ value }) {
      console.log('visitFunctionExpression', index++)
      const id = `function_${value.loc.start.line}_${value.loc.start.column}`
      recordFunction(value, id)
      logFunctionId(value)
      recordAllFunctions(value.body)
      return false
    },
    // 3
    visitVariableDeclaration: function ({ value }) {
      console.log('visitVariableDeclaration:', index++)
      forRecordCycle(value.declarations)
      return false
    },
    // 4
    visitVariableDeclarator: function ({ value }) {
      console.log('visitVariableDeclarator', index++)
      recordAllFunctions(value.init)
      return false
    },
    // 5
    visitCallExpression: function ({ value }) {
      console.log('visitCallExpression', index++)
      recordAllFunctions(value.callee)
      forRecordCycle(value.arguments)
      return false
    },
    // 6
    visitReturnStatement: function ({ value }) {
      console.log('visitReturnStatement', index++)
      recordAllFunctions(value.argument)
      return false
    },
    // 7
    visitExpressionStatement: function ({ value }) {
      console.log('visitExpressionStatement', index++)
      recordAllFunctions(value.expression)
      return false
    },
    // 8
    visitUnaryExpression: function ({ value }) {
      console.log('visitUnaryExpression', index++)
      recordAllFunctions(value.argument)
      return false
    },
    // 9
    visitSequenceExpression: function ({ value }) {
      console.log('visitSequenceExpression', index++)
      forRecordCycle(value.expressions)
      return false
    },
    // 10
    visitAssignmentExpression: function ({ value }) {
      console.log('visitAssignmentExpression', index++)
      recordAllFunctions(value.right)
      return false
    },
    // 11
    visitConditionalExpression: function ({ value }) {
      console.log('visitConditionalExpression', index++)
      recordAllFunctions(value.test)
      recordAllFunctions(value.consequent)
      recordAllFunctions(value.alternate)
      return false
    },
    // 12
    visitLogicalExpression: function ({ value }) {
      console.log('visitLogicalExpression', index++)
      recordAllFunctions(value.left)
      recordAllFunctions(value.right)
      return false
    },
    // 13
    visitIfStatement: function ({ value }) {
      console.log('visitIfStatement', index++)
      recordAllFunctions(value.test)
      recordAllFunctions(value.consequent)
      recordAllFunctions(value.alternate)
      return false
    },
    // 14
    visitUnaryExpression: function ({ value }) {
      console.log('visitUnaryExpression', index++)
      recordAllFunctions(value.argument)
      return false
    },
    // 15
    visitArrayExpression: function ({ value }) {
      console.log('visitArrayExpression', index++)
      forRecordCycle(value.elements)
      return false
    },
    // 16
    visitObjectExpression: function ({ value }) {
      console.log('visitObjectExpression', index++)
      forRecordCycle(value.properties)
      return false
    },
    // 17
    visitProperty: function ({ value }) {
      console.log('visitProperty', index++)
      recordAllFunctions(value.value)
      return false
    },
    // 18
    visitForStatement: function ({ value }) {
      console.log('visitForStatement', index++)
      recordAllFunctions(value.init)
      recordAllFunctions(value.body)
      return false
    },
    // 19
    visitWhileStatement: function ({ value }) {
      console.log('visitWhileStatement', index++)
      recordAllFunctions(value.body)
      return false
    },
    // 20
    visitDoWhileStatement: function ({ value }) {
      console.log('visitDoWhileStatement', index++)
      recordAllFunctions(value.body)
      return false
    },
    // 21
    visitBlockStatement: function ({ value }) {
      console.log('visitBlockStatement', index++)
      forRecordCycle(value.body)
      return false
    },
    // 22
    visitSwitchStatement: function ({ value }) {
      console.log('visitSwitchStatement', index++)
      forRecordCycle(value.cases)
      return false
    },
    // 23
    visitSwitchCase: function ({ value }) {
      console.log('visitSwitchCase', index++)
      forRecordCycle(value.consequent)
      return false
    },
    // 24
    visitThrowStatement: function ({ value }) {
      console.log('visitThrowStatement', index++)
      recordAllFunctions(value.argument)
      return false
    },
    // 25
    visitTryStatement: function ({ value }) {
      console.log('visitThrowStatement', index++)
      recordAllFunctions(value.block)
      recordAllFunctions(value.handler)
      return false
    },
    // 26
    visitCatchClause: function ({ value }) {
      console.log('visitThrowStatement', index++)
      recordAllFunctions(value.body)
      return false
    },
  })
}

function removeUFFFunctions(node) {
  const arrRemoved = fs.readFileSync('functions-removed').toString().split('\n')
  recast.visit(node, {
    // 1
    visitFunctionDeclaration: function ({ value }) {
      console.log('visitFunctionDeclaration:', index++)
      const id = `function_${value.loc.start.line}_${value.loc.start.column}`
      if (arrRemoved.indexOf(id) >= 0) removeUFF(value, id)
      else {
        removeUFFFunctions(value.body)
      }
      return false
    },
    // 2
    visitFunctionExpression: function ({ value }) {
      console.log('visitFunctionExpression', index++)
      const id = `function_${value.loc.start.line}_${value.loc.start.column}`
      if (arrRemoved.indexOf(id) >= 0) removeUFF(value, id)
      else {
        removeUFFFunctions(value.body)
      }

      return false
    },
    // 3
    visitVariableDeclaration: function ({ value }) {
      console.log('visitVariableDeclaration:', index++)
      forRemoveCycle(value.declarations)
      return false
    },
    // 4
    visitVariableDeclarator: function ({ value }) {
      console.log('visitVariableDeclarator', index++)
      removeUFFFunctions(value.init)
      return false
    },
    // 5
    visitCallExpression: function ({ value }) {
      console.log('visitCallExpression', index++)
      removeUFFFunctions(value.callee)
      forRemoveCycle(value.arguments)
      return false
    },
    // 6
    visitReturnStatement: function ({ value }) {
      console.log('visitReturnStatement', index++)
      removeUFFFunctions(value.argument)
      return false
    },
    // 7
    visitExpressionStatement: function ({ value }) {
      console.log('visitExpressionStatement', index++)
      removeUFFFunctions(value.expression)
      return false
    },
    // 8
    visitUnaryExpression: function ({ value }) {
      console.log('visitUnaryExpression', index++)
      removeUFFFunctions(value.argument)
      return false
    },
    // 9
    visitSequenceExpression: function ({ value }) {
      console.log('visitSequenceExpression', index++)
      forRemoveCycle(value.expressions)
      return false
    },
    // 10
    visitAssignmentExpression: function ({ value }) {
      console.log('visitAssignmentExpression', index++)
      removeUFFFunctions(value.right)
      return false
    },
    // 11
    visitConditionalExpression: function ({ value }) {
      console.log('visitConditionalExpression', index++)
      removeUFFFunctions(value.test)
      removeUFFFunctions(value.consequent)
      removeUFFFunctions(value.alternate)
      return false
    },
    // 12
    visitLogicalExpression: function ({ value }) {
      console.log('visitLogicalExpression', index++)
      removeUFFFunctions(value.left)
      removeUFFFunctions(value.right)
      return false
    },
    // 13
    visitIfStatement: function ({ value }) {
      console.log('visitIfStatement', index++)
      removeUFFFunctions(value.consequent)
      removeUFFFunctions(value.alternate)
      return false
    },
    // 14
    visitUnaryExpression: function ({ value }) {
      console.log('visitUnaryExpression', index++)
      removeUFFFunctions(value.argument)
      return false
    },

    // 15
    visitArrayExpression: function ({ value }) {
      console.log('visitArrayExpression', index++)
      forRemoveCycle(value.elements)
      return false
    },
    // 16
    visitObjectExpression: function ({ value }) {
      console.log('visitObjectExpression', index++)
      forRemoveCycle(value.properties)
      return false
    },
    // 17
    visitProperty: function ({ value }) {
      console.log('visitProperty', index++)
      removeUFFFunctions(value.value)
      return false
    },
    // 18
    visitForStatement: function ({ value }) {
      console.log('visitForStatement', index++)
      removeUFFFunctions(value.init)
      removeUFFFunctions(value.body)
      return false
    },
    // 19
    visitWhileStatement: function ({ value }) {
      console.log('visitWhileStatement', index++)
      removeUFFFunctions(value.body)
      return false
    },
    // 20
    visitDoWhileStatement: function ({ value }) {
      console.log('visitDoWhileStatement', index++)
      removeUFFFunctions(value.body)
      return false
    },
    // 21
    visitBlockStatement: function ({ value }) {
      console.log('visitBlockStatement', index++)
      forRemoveCycle(value.body)
      return false
    },
    // 22
    visitSwitchStatement: function ({ value }) {
      console.log('visitSwitchStatement', index++)
      forRemoveCycle(value.cases)
      return false
    },
    // 23
    visitSwitchCase: function ({ value }) {
      console.log('visitSwitchCase', index++)
      forRemoveCycle(value.consequent)
      return false
    },
    // 24
    visitThrowStatement: function ({ value }) {
      console.log('visitThrowStatement', index++)
      removeUFFFunctions(value.argument)
      return false
    },
    // 25
    visitTryStatement: function ({ value }) {
      console.log('visitThrowStatement', index++)
      removeUFFFunctions(value.block)
      removeUFFFunctions(value.handler)
      return false
    },
    // 26
    visitCatchClause: function ({ value }) {
      console.log('visitThrowStatement', index++)
      removeUFFFunctions(value.body)
      return false
    },
  })
}

/*
 * function randomFunctionsToFile() {
 *   const arr = fs.readFileSync("functions.js").toString().split("\n");
 *   console.log(arr.slice(0, REMOVE_NUM));
 *   randomMFromN(REMOVE_NUM, arr.length, arr);
 * }
 *
 * function randomMFromN(m, n, arr) {
 *   fs.writeFileSync("functionsRemoved.js", "", "utf-8");
 *   for (let i = 0; i < m; i++) {
 *     const j = Math.floor(Math.random() * (n - i)) + i;
 *     const tmp = arr[i];
 *     arr[i] = arr[j];
 *     arr[j] = tmp;
 *     fs.appendFileSync("functionsRemoved.js", arr[i] + "\n", "utf-8");
 *   }
 *   console.log(arr.slice(0, m));
 * }
 */

module.exports = {
  recordAllFunctions,
  removeUFFFunctions,
}
