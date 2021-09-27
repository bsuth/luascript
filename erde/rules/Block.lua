local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Block = {
    pattern = _.Sum({
      _.Pad(_.Sum({
        _.CsV('Comment'),
        -- allow function calls as statements
        _.CsV('IdExpr') * _.B(')'),
        _.CsV('Assignment'),
        _.CsV('NameDeclaration'),
        _.CsV('FunctionDeclaration'),
        _.CsV('AssignOp'),
        _.CsV('Return'),
        _.CsV('IfElse'),
        _.CsV('NumericFor'),
        _.CsV('GenericFor'),
        _.CsV('WhileLoop'),
        _.CsV('RepeatUntil'),
        _.CsV('DoBlock'),
      })) ^ 1,
      -- Allow empty blocks. We have to produce at least one capture here or the
      -- entire V('Space') match will be passed
      _.Cc(true) * _.V('Space')
    }),
    compiler = _.concat('\n'),
    formatter = _.concat('\n'),
  },
  BraceBlock = {
    pattern = _.Pad('{') * _.CsV('Block') * _.Pad('}'),
  },
  NameDeclaration = {
    pattern = _.Product({
      _.Sum({
        _.Pad('local') * _.Cc(true),
        _.Pad('global') * _.Cc(false),
      }),
      _.Sum({
        _.V('Destructure') * _.Cc(true),
        _.CsV('Name') * _.Cc(false),
      }),
      (_.Pad('=') * _.CsV('Expr')) ^ -1,
    }),
    compiler = function(islocal, declaree, isdestructure, expr)
      local prefix = islocal and 'local ' or ''
      if isdestructure then
        return _.compiledestructure(islocal, declaree, expr)
      elseif expr then
        return ('%s%s = %s'):format(prefix, declaree, expr)
      elseif islocal then
        return ('%s%s'):format(prefix, declaree)
      else
        -- global declarations with no initializer do not warrant an output
        -- ex) `global x`
        return ''
      end
    end,
  },
  Assignment = {
    pattern = _.V('Id') * _.Pad('=') * _.CsV('Expr'),
    compiler = _.indexchain(_.template('%1 = %2')),
  },
}
