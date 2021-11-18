-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Destructure.parse', function()
  spec('ruleName', function()
    assert.are.equal('Destructure', parse.Destructure('{ a }').ruleName)
  end)

  spec('destructure keyDestruct', function()
    assert.has_subtable({
      { name = 'a', variant = 'keyDestruct' },
    }, parse.Destructure(
      '{ a }'
    ))
    assert.has_error(function()
      parse.Destructure('{}')
    end)
  end)

  spec('destructure numberDestruct', function()
    assert.has_subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '[ a, b ]'
    ))
    assert.has_subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{[ a, b ]}'
    ))
    assert.has_subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{[a], [b]}'
    ))
  end)

  spec('destructure mixed', function()
    assert.has_subtable({
      { name = 'a', variant = 'keyDestruct' },
      { name = 'b', variant = 'numberDestruct' },
      { name = 'c', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{ a, [b, c]}'
    ))
  end)

  spec('optional destructure', function()
    assert.has_subtable({
      optional = true,
      { name = 'a' },
    }, parse.Destructure(
      '?{ a }'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Destructure.compile', function()
  spec('sanity check', function()
    assert.is_not_nil(compile.Destructure('{ a }').baseName)
    assert.is_not_nil(compile.Destructure('{ a }').compiled)
  end)
end)
