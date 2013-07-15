import AbstractCompiler from './abstract_compiler'
import { isEmpty } from './utils'
import path from 'path'

class UMDCompiler extends AbstractCompiler
  stringify: ->
    @build (s) =>

      [ wrapperArgs, preamble ] = @buildPreamble(@dependencyNames)

      unless isEmpty(@exports)
        @dependencyNames.push 'exports'
        wrapperArgs.push 'exports'

      for i of @dependencyNames
        dependency = @dependencyNames[i]
        if /^\./.test(dependency)
          # '..' makes up for path.join() treating a module name w/ no extension
          # as a folder
          @dependencyNames[i] = path.join(@moduleName, '..', dependency).replace(/[\\]/g, '/')

      inner = s.capture =>
        s.function ['factory'], =>
          s.append "if (typeof define === 'function' && define.amd) {"
          s.indent()

          s.line =>
            s.call 'define', (arg) =>
              arg s.print(@moduleName) if @moduleName
              arg s.break
              arg s.print(@dependencyNames)
              arg s.break
              arg =>
                s.function wrapperArgs, =>
                  factoryCall = s.capture => s.call 'factory', (factoryArgs) =>
                    factoryArgs wrapperArgs

                  s.line "#{if @exportDefault then 'return ' else '' }#{factoryCall}"

          s.outdent()
          s.append "} else if (typeof exports === 'object') {"
          s.indent()

          cjsArgs = []
          for own import_, name of @importDefault
            cjsArgs.push s.capture => s.call 'require', [s.print(import_)]
          for own import_, variables of @imports
            cjsArgs.push s.capture => s.call 'require', [s.print(import_)]
          cjsArgs.push 'exports' unless isEmpty(@exports)

          factoryCall = s.capture => s.call 'factory', (factoryArgs) =>
            factoryArgs cjsArgs
          s.line "#{if @exportDefault then 'module.exports = ' else '' }#{factoryCall}"
          s.outdent()
          s.append "} else {"
          s.indent()
          s.line "throw new Error('root UMD compilation not yet implemented')"
          s.outdent()
          s.append "}"

      deps = s.unique('dependency')

      inParen = s.capture =>
        s.call inner, (args) =>
          args =>
            s.function wrapperArgs, =>
              s.useStrict()

              for own import_, variables of @imports
                if false && Object.keys(variables).length is 1 # TODO REMOVE THIS?
                  # var foo = require('./foo').foo;
                  name = Object.keys(variables)[0]
                else
                  # var __dependency1__ = require('./foo');
                  dependency = deps.next()

                  # var foo = __dependency1__.foo;
                  # var bar = __dependency1__.bar;
                  for own name, alias of variables
                    if name == 'default'
                      s.var alias, "#{dependency}"
                    else
                      s.var alias, "#{dependency}.#{name}"

              s.append @lines...

              for exportName, exportValue of @exports
                s.line "exports.#{exportName} = #{exportValue}"

              if @exportDefault
                s.line "return #{@exportDefault}"
      s.line "(#{inParen})"

export default UMDCompiler

