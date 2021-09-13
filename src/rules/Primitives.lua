require('env')()

return {
  Integer = {
    parser = digit ^ 1,
    compiler = echo,
  },
  Hex = {
    parser = (P('0x') + P('0X')) * xdigit ^ 1,
    compiler = echo,
  },
  Exponent = {
    parser = S('eE') * S('+-') ^ -1 * V('Integer'),
    compiler = echo,
  },
  Float = {
    parser = Sum({
      digit ^ 0 * P('.') * V('Integer') * V('Exponent') ^ -1,
      V('Integer') * V('Exponent'),
    }),
    compiler = echo,
  },
  Number = {
    parser = C(V('Float') + V('Hex') + V('Integer')),
    compiler = echo,
  },
  EscapedChar = {
    parser = C(V('Newline') + P('\\') * P(1)),
    compiler = echo,
  },
  Interpolation = {
    parser = P('{') * Pad(Demand(V('Expr'))) * P('}'),
    compiler = function(value)
      return { interpolation = true, value = value }
    end,
  },
  LongString = {
    parser = Product({
      P('`'),
      Sum({
        V('EscapedChar'),
        V('Interpolation'),
        C(P(1) - P('`')),
      }) ^ 0,
      P('`'),
    }),
    compiler = function(...)
      local values = supertable({ ... })

      local eqstats = values:reduce(function(eqstats, char)
        return char ~= '='
          and { counter = 0, max = eqstats.max }
          or {
            counter = eqstats.counter + 1,
            max = math.max(eqstats.max, eqstats.counter + 1),
          }
      end, { counter = 0, max = 0 })

      local eqstr = ('='):rep(eqstats.max + 1)

      return ('[%s[%s]%s]'):format(
        eqstr,
        values:map(function(v)
          return v.interpolation
            and (']%s]..tostring(%s)..[%s['):format(eqstr, v.value, eqstr)
            or v
        end):join(),
        eqstr
      )
    end,
  },
  String = {
    parser = Sum({
      V('LongString'),
      C("'") * (V('EscapedChar') + C(1) - P("'")) ^ 0 * C("'"), -- single quote
      C('"') * (V('EscapedChar') + C(1) - P('"')) ^ 0 * C('"'), -- double quote
    }),
    compiler = echo,
  },
}
