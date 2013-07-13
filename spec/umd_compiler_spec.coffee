{ shouldCompileUMD, shouldRaise, shouldRunCLI } = require './spec_helper'

describe "Compiler (toUMD)", ->
  it 'generates a single export if `export default` is used', ->
    shouldCompileUMD """
      var jQuery = function() { };

      export default jQuery;
    """, """
      (function (root, factory) {
        if (typeof define === 'function' && define.amd) {
          define(function () {
            return factory();
          });
        } else if (typeof exports === 'object') {
          module.exports = factory();
        } else {
          root.jQuery = factory();
        }
      }(this, function () {
        var jQuery = function() { };

        return {};
      }));
    """

  it 'generates an export object if `export foo` is used', ->
    shouldCompileUMD """
      var jQuery = function() { };

      export jQuery;
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['exports'], function (exports) {
            factory(exports);
          });
        } else if (typeof exports === 'object') {
          factory(exports);
        }
      }(function (exports) {
        var jQuery = function() { };

        exports.jQuery = jQuery;
      }));
    """

  it 'generates an export object if `export function foo` is used', ->
    shouldCompileUMD """
      export function jQuery() { };
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['exports'], function (exports) {
            factory(exports);
          });
        } else if (typeof exports === 'object') {
          factory(exports);
        }
      }(function (exports) {
        function jQuery() { };
        exports.jQuery = jQuery;
      }));
    """

  it 'generates an export object if `export var foo` is used', ->
    shouldCompileUMD """
      export var jQuery = function() { };
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['exports'], function (exports) {
            factory(exports);
          });
        } else if (typeof exports === 'object') {
          factory(exports);
        }
      }(function (exports) {
        var jQuery = function() { };
        exports.jQuery = jQuery;
      }));
    """

  it 'generates an export object if `export { foo, bar }` is used', ->
    shouldCompileUMD """
      var get = function() { };
      var set = function() { };

      export { get, set };
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['exports'], function (exports) {
            factory(exports);
          });
        } else if (typeof exports === 'object') {
          factory(exports);
        }
      }(function (exports) {
        var get = function() { };
        var set = function() { };

        exports.get = get;
        exports.set = set;
      }));

    """

  it 'raises if both `export default` and `export foo` are used', ->
    shouldRaise """
      export { get, set };
      export default Ember;
    """, "You cannot use both `export default` and `export` in the same module"

  it 'converts `import { get, set } from "ember"', ->
    shouldCompileUMD """
      import { get, set } from "ember";
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['ember'], function (ember) {
            factory(ember);
          });
        } else if (typeof exports === 'object') {
          factory(require('ember'));
        }
      }(function (exports, __dependency1__) {
        var get = __dependency1__.get;
        var set = __dependency1__.set;
      }));
    """

  it 'support single quotes in import {x, y} from z', ->
    shouldCompileUMD """
      import { get, set } from 'ember';
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['ember'], function (__dependency1__) {
            factory(__dependency1__);
          });
        } else if (typeof exports === 'object') {
          factory(require('ember'));
        }
      }(function (exports, __dependency1__) {
        var get = __dependency1__.get;
        var set = __dependency1__.set;
      }));
    """

  it 'converts `import foo from "bar"`', ->
    shouldCompileUMD """
      import _ from "underscore";
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['underscore'], function (_) {
            factory(_);
          });
        } else if (typeof exports === 'object') {
          factory(require('underscore'));
        }
      }(function (_) {
      }));
    """

  it 'supports single quotes in import x from y', ->
    shouldCompileUMD """
      import undy from 'underscore';
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['underscore'], function (undy) {
            factory(undy);
          });
        } else if (typeof exports === 'object') {
          factory(require('underscore'));
        }
      }(function (undy) {
      }));
    """

  it 'supports import { x as y } from "foo"', ->
    shouldCompileUMD """
      import { View as EmView } from 'ember';
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['ember'], function (__dependency1__) {
            factory(__dependency1__);
          });
        } else if (typeof exports === 'object') {
          factory(require('ember'));
        }
      }(function (__dependency1__) {
        var EmView = __dependency1__.View;
      }));
    """

  it 'supports import { default as foo } from "foo"', ->
    shouldCompileUMD """
      import { View as EmView, default as Ember } from 'ember';
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['ember'], function (__dependency1__) {
            factory(__dependency1__);
          });
        } else if (typeof exports === 'object') {
          factory(require('ember'));
        }
      }(function (__dependency1__) {
        var EmView = __dependency1__.View;
        var Ember = __dependency1__;
      }));
    """

  it 'can re-export a subset of another module', ->
    shouldCompileUMD """
      export { ajax, makeArray } from "jquery";
    """, """
      (function (factory) {
        if (typeof define === 'function' && define.amd) {
          define(['jquery'], function (__reexport1__) {
            factory(__reexport1__);
          });
        } else if (typeof exports === 'object') {
          factory(require('jquery'));
        }
      }(function (__reexport1__) {
        exports.ajax = __reexport1__.ajax;
        exports.makeArray = __reexport1__.makeArray;
      }));
    """

