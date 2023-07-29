arrr = require 'arrr'

describe 'arrr', ->
	describe 'constructor', ->
		it 'returns a callable table', ->
			assert.is.table arrr{}
			assert.is.function getmetatable(arrr{}).__call
	
	describe 'parser', ->
		before_each ->
			export handler = arrr {
				{ 'Flag', '--flag' }
				{ 'Foo', '--foo', '-f', true }
				{ 'Bar', '--bar', '-b', true }
				{ 'Baz', '--baz',  nil, 2 }
				{ 'Moo', '--moo',  nil, true }
				{ 'Zoo', '--zoo',  nil, { 'param' } }
				{ 'Boo', '--boo',  nil, { 'duck', 'russian_spy' } }
				{ 'Var', '--var',  nil, '*' }
				{ 'Del', '--del',  nil, '--' }
			}

		it 'parses long arguments', ->
			assert.same { foo: 'Foo', bar: 'Bar' },
				handler { '--foo', 'Foo', '--bar', 'Bar' }

		it 'parses short arguments', ->
			assert.same { foo: 'Foo', bar: 'Bar' },
				handler { '-f', 'Foo', '-b', 'Bar' }

		it 'parses combined short arguments', ->
			assert.same { foo: 'Foo', bar: 'Bar' },
				handler { '-fb', 'Foo', 'Bar' }

		it 'ignores single param names', ->
			-- These are just for documentation purposes!
			assert.same { moo: 'oom' },
				handler { '--moo', 'oom' }

		it 'parses flags as booleans', ->
			assert.same { flag: true }, handler { '--flag' }

		it 'collect multiparams automatically', ->
			assert.same { baz: {'bzzz', 'brrr'} },
				handler { '--baz', 'bzzz', 'brrr' }

		it 'uses given multiparams names', ->
			assert.same { zoo: { param: 'kvak' } },
				handler { '--zoo', 'kvak' }
			assert.same { boo: { duck: 'quack', russian_spy: 'kvak' } },
				handler { '--boo', 'quack', 'kvak' }

		it 'should ignore unknown long parameters', ->
			assert.same { foo: 'foo', '--buu', 'buu' },
				handler { '--foo', 'foo', '--buu', 'buu' }

		it 'should ignore single unknown short parameters', ->
			assert.same { '-X', 'test' },
				handler { '-X', 'test' }

		it 'should call a hook for unknown long parameters', ->
			callback = stub.new()
			parser = arrr {}
			parser.unknown = (first) -> callback first
			assert.same {'--foo', 'bar'}, parser { '--foo', 'bar' }
			assert.stub(callback).was_called_with '--foo'

		it 'should call a hook for unknown short parameters', ->
			callback = stub.new()
			parser = arrr {}
			parser.unknown = (first) -> callback first
			assert.same {'-f', 'bar'}, parser { '-f', 'bar' }
			assert.stub(callback).was_called_with '-f'

		it 'should drop unknown parameters when the callback returns true', ->
			parser = arrr {}
			parser.unknown = -> true
			assert.same {'bar'}, parser { '--foo', '-f', 'bar' }

		it 'should pass the output object to the callback', ->
			parser = arrr{}
			parser.unknown = (token, list) -> table.insert(list, token\upper!) or true
			assert.same { "--FOO" }, parser { "--foo" }
			parser.unknown = (token, list) -> rawset(list, 'unknown', token\upper!) or true
			assert.same { unknown: "--FOO" }, parser { "--foo" }

		it 'should split multiple unknown short parameters', ->
			assert.same { '-X', '-Y', '-Z', 'test' },
				handler { '-XYZ', 'test' }

		it 'should extract unknown short parameters in mixed lists', ->
			assert.same { '-X', '-Z', foo: 'test' },
				handler { '-XfZ', 'test' }

		it 'parses variable argument lists for "*"', ->
			assert.same { foo: 'foo', var: { 'first', 'second', 'third' } },
				handler { '--var', 'first', 'second', 'third', '--foo', 'foo' }

		it 'accepts delimiter parameters', ->
			assert.same { del: { "a", "b", "c" }, "bar", "baz" },
				handler { "--del", "a", "b", "c", "--", "bar", "--", "baz" }

		it 'aborts on double dash', ->
			assert.same { foo: 'foo', 'bar', '--baz' },
				handler { '--foo', 'foo', '--', 'bar', '--baz' }

		it 'filters single arguments', ->
			parse = arrr { { "Filtered", "--filtered", nil, true, filter: => @upper! } }
			assert.same { filtered: "VALUE" },
				parse { "--filtered", "value" }

		it 'filters tables as a whole', ->
			parse = arrr {
				{ "Array", "--filtered1", nil, 3, filter: => assert.is.table @ }
				{ "Map", "--filtered2", nil, {"foo", "bar"}, filter: => assert.is.table @ }
			}
			parse { "--filtered1", "a", "b", "c", "--filtered2", 1, 2 }

		it 'parses arguments with dashes', ->
			long = arrr { { "Long argument", "--foo-bar", nil, true } }
			assert.same { 'foobar': 'Hello, World!' },
				long { '--foo-bar', 'Hello, World!' }
