local utils = require('erde.utils')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Number.parse', function()
  spec('integer', function()
    assert.are.equal('9', parse.Number('9').value)
    assert.are.equal('43', parse.Number('43').value)
  end)

  spec('hex', function()
    assert.are.equal('0x4', parse.Number('0x4').value)
    assert.are.equal('0xd', parse.Number('0xd').value)
    assert.are.equal('0Xf', parse.Number('0Xf').value)
    assert.are.equal('0xa8F', parse.Number('0xa8F').value)

    if not _VERSION:find('5%.1') then
      assert.are.equal('0xfp2', parse.Number('0xfp2').value)
      assert.are.equal('0xfP2', parse.Number('0xfP2').value)
      assert.are.equal('0xf.1', parse.Number('0xf.1').value)
      assert.are.equal('0xfp+2', parse.Number('0xfp+2').value)
      assert.are.equal('0xfp-2', parse.Number('0xfp-2').value)
    end

    assert.has_error(function()
      parse.Number('x3')
    end)
    assert.has_error(function()
      parse.Number('0x')
    end)
    assert.has_error(function()
      parse.Number('0xg')
    end)
    assert.has_error(function()
      parse.Number('0xfp+')
    end)
    assert.has_error(function()
      parse.Number('0xfp-')
    end)
    assert.has_error(function()
      parse.Number('0xfpa')
    end)
  end)

  spec('floats', function()
    assert.are.equal('.34', parse.Number('.34').value)
    assert.are.equal('0.3', parse.Number('0.3').value)
    assert.are.equal('10.33', parse.Number('10.33').value)
    assert.has_error(function()
      parse.Number('4.')
    end)
  end)

  spec('exponents', function()
    assert.are.equal('9e2', parse.Number('9e2').value)
    assert.are.equal('9.2E21', parse.Number('9.2E21').value)
    assert.are.equal('9e+2', parse.Number('9e+2').value)
    assert.are.equal('.8e-2', parse.Number('.8e-2').value)
    assert.has_error(function()
      parse.Number('9e')
    end)
    assert.has_error(function()
      parse.Number('9e+')
    end)
    assert.has_error(function()
      parse.Number('9e-')
    end)
    assert.has_error(function()
      parse.Number('e2')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Number.compile', function()
  spec('integer', function()
    assert.eval(9, compile.Number('9'))
    assert.eval(43, compile.Number('43'))
  end)

  spec('hex', function()
    assert.eval(0x4, compile.Number('0x4'))
    assert.eval(0xd, compile.Number('0xd'))
    assert.eval(0Xf, compile.Number('0Xf'))
    assert.eval(0xa8F, compile.Number('0xa8F'))

    if not _VERSION:find('5%.1') then
      -- No eval necessary here. Technically Lua5.1 supports hex exponents,
      -- although it is undocumented
      assert.eval(0xfp2, compile.number('0xfp2'))
      assert.eval(0xfp2, compile.number('0xfp2'))

      -- Need to eval to prevent parsing errors for lower lua versions.
      assert.eval(utils.eval('0xf.1'), compile.Number('0xf.1'))
      assert.eval(utils.eval('0xfp+2'), compile.Number('0xfp+2'))
      assert.eval(utils.eval('0xfp-2'), compile.Number('0xfp-2'))
    end

    if _VERSION:find('5%.[34]') then
    end
  end)

  spec('floats', function()
    assert.eval(.34, compile.Number('.34'))
    assert.eval(0.3, compile.Number('0.3'))
    assert.eval(10.33, compile.Number('10.33'))
  end)

  spec('exponents', function()
    assert.eval(9e2, compile.Number('9e2'))
    assert.eval(9.2E21, compile.Number('9.2E21'))
    assert.eval(9e+2, compile.Number('9e+2'))
    assert.eval(.8e-2, compile.Number('.8e-2'))
  end)
end)
