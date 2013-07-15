(function() {
  "use strict";

  var AbstractCompiler, UMDCompiler, isEmpty, path,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  AbstractCompiler = require("./abstract_compiler");

  path = require("path");

  isEmpty = require("./utils").isEmpty;

  UMDCompiler = (function(_super) {

    __extends(UMDCompiler, _super);

    function UMDCompiler() {
      return UMDCompiler.__super__.constructor.apply(this, arguments);
    }

    UMDCompiler.prototype.stringify = function() {
      var _this = this;
      return this.build(function(s) {
        var dependency, deps, i, inParen, inner, preamble, wrapperArgs, _ref;
        _ref = _this.buildPreamble(_this.dependencyNames), wrapperArgs = _ref[0], preamble = _ref[1];
        if (!isEmpty(_this.exports)) {
          _this.dependencyNames.push('exports');
          wrapperArgs.push('exports');
        }
        for (i in _this.dependencyNames) {
          dependency = _this.dependencyNames[i];
          if (/^\./.test(dependency)) {
            _this.dependencyNames[i] = path.join(_this.moduleName, '..', dependency).replace(/[\\]/g, '/');
          }
        }
        inner = s.capture(function() {
          return s["function"](['factory'], function() {
            var cjsArgs, factoryCall, import_, name, variables, _ref1, _ref2;
            s.append("if (typeof define === 'function' && define.amd) {");
            s.indent();
            s.line(function() {
              return s.call('define', function(arg) {
                if (_this.moduleName) {
                  arg(s.print(_this.moduleName));
                }
                arg(s["break"]);
                arg(s.print(_this.dependencyNames));
                arg(s["break"]);
                return arg(function() {
                  return s["function"](wrapperArgs, function() {
                    var factoryCall;
                    factoryCall = s.capture(function() {
                      return s.call('factory', function(factoryArgs) {
                        return factoryArgs(wrapperArgs);
                      });
                    });
                    return s.line("" + (_this.exportDefault ? 'return ' : '') + factoryCall);
                  });
                });
              });
            });
            s.outdent();
            s.append("} else if (typeof exports === 'object') {");
            s.indent();
            cjsArgs = [];
            _ref1 = _this.importDefault;
            for (import_ in _ref1) {
              if (!__hasProp.call(_ref1, import_)) continue;
              name = _ref1[import_];
              cjsArgs.push(s.capture(function() {
                return s.call('require', [s.print(import_)]);
              }));
            }
            _ref2 = _this.imports;
            for (import_ in _ref2) {
              if (!__hasProp.call(_ref2, import_)) continue;
              variables = _ref2[import_];
              cjsArgs.push(s.capture(function() {
                return s.call('require', [s.print(import_)]);
              }));
            }
            if (!isEmpty(_this.exports)) {
              cjsArgs.push('exports');
            }
            factoryCall = s.capture(function() {
              return s.call('factory', function(factoryArgs) {
                return factoryArgs(cjsArgs);
              });
            });
            s.line("" + (_this.exportDefault ? 'module.exports = ' : '') + factoryCall);
            s.outdent();
            s.append("} else {");
            s.indent();
            s.line("throw new Error('root UMD compilation not yet implemented')");
            s.outdent();
            return s.append("}");
          });
        });
        deps = s.unique('dependency');
        inParen = s.capture(function() {
          return s.call(inner, function(args) {
            return args(function() {
              return s["function"](wrapperArgs, function() {
                var alias, exportName, exportValue, import_, name, variables, _ref1, _ref2;
                s.useStrict();
                _ref1 = _this.imports;
                for (import_ in _ref1) {
                  if (!__hasProp.call(_ref1, import_)) continue;
                  variables = _ref1[import_];
                  if (false && Object.keys(variables).length === 1) {
                    name = Object.keys(variables)[0];
                  } else {
                    dependency = deps.next();
                    for (name in variables) {
                      if (!__hasProp.call(variables, name)) continue;
                      alias = variables[name];
                      if (name === 'default') {
                        s["var"](alias, "" + dependency);
                      } else {
                        s["var"](alias, "" + dependency + "." + name);
                      }
                    }
                  }
                }
                s.append.apply(s, _this.lines);
                _ref2 = _this.exports;
                for (exportName in _ref2) {
                  exportValue = _ref2[exportName];
                  s.line("exports." + exportName + " = " + exportValue);
                }
                if (_this.exportDefault) {
                  return s.line("return " + _this.exportDefault);
                }
              });
            });
          });
        });
        return s.line("(" + inParen + ")");
      });
    };

    return UMDCompiler;

  })(AbstractCompiler);

  module.exports = UMDCompiler;

}).call(this);
