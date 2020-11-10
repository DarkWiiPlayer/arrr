arrr = require 'arrr'

describe 'arrr', ->
	describe 'constructor', ->
		it 'returns a callable table', ->
			assert.is.table arrr{}
			assert.is.function getmetatable(arrr{}).__call
	
	describe 'parser', ->
		before_each ->
			export handler = arrr {
				{ "Flag", "--flag" }
				{ "Foo", "--foo", "-f", 'foo' }
				{ "Bar", "--bar", "-b", 'bar' }
				{ "Baz", "--baz",  nil, 2 }
				{ "Moo", "--moo",  nil, 'param' }
				{ "Zoo", "--zoo",  nil, { 'param' } }
				{ "Boo", "--boo",  nil, { 'duck', 'russian_spy' } }
			}

		it 'parses flags as booleans', ->
			assert.same { flag: true }, handler { "--flag" }

		it 'parses long arguments', ->
			assert.same { foo: "Foo", bar: "Bar" },
				handler { "--foo", 'Foo', "--bar", 'Bar' }

		it 'parses short arguments', ->
			assert.same { foo: "Foo", bar: "Bar" },
				handler { "-f", 'Foo', "-b", 'Bar' }

		it 'parses combined short arguments', ->
			assert.same { foo: "Foo", bar: "Bar" },
				handler { "-fb", 'Foo', 'Bar' }

		it 'ignores single param names', ->
			-- These are just for documentation purposes!
			assert.same { moo: "oom" },
				handler { "--moo", "oom" }

		it 'collect multiparams automatically', ->
			assert.same { baz: {"bzzz", "brrr"} },
				handler { "--baz", "bzzz", "brrr" }

		it 'uses given multiparams names', ->
			assert.same { zoo: { param: "kvak" } },
				handler { "--zoo", "kvak" }
			assert.same { boo: { duck: "quack", russian_spy: "kvak" } },
				handler { "--boo", "quack", "kvak" }

		it 'should ignore unknown long parameters', ->
			assert.same { foo: "foo", "--buu", "buu" },
				handler { "--foo", "foo", "--buu", "buu" }

		it 'should ignore single unknown short parameters', ->
			assert.same { "-X", 'test' },
				handler { "-X", 'test' }

		it 'should split multiple unknown short parameters', ->
			assert.same { "-X", "-Y", "-Z", 'test' },
				handler { "-XYZ", 'test' }

		it 'should extract unknown short parameters in mixed lists', ->
			assert.same { "-X", "-Z", foo: 'test' },
				handler { "-XfZ", 'test' }

		it 'should stop parsing after double dash', ->
			assert.same { foo: "foo", "bar", "--baz" },
				handler { "--foo", "foo", "bar", "--", "--baz" }
