// Generated by CoffeeScript 1.3.3
var fs, path, _,
  __slice = [].slice;

path = require('path');

fs = require('fs');

_ = require('underscore');

module.exports = function() {
  return [
    "file", 10, function() {
      var args, base, file, fobj, full, next, _i, _ref,
        _this = this;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), next = arguments[_i++];
      file = args[0], base = args[1];
      if (!(_.isString(file) || _.isObject(file))) {
        return next();
      }
      if (_.isObject(file)) {
        if (!file.file) {
          return next();
        } else {
          _ref = [file, file.file], fobj = _ref[0], file = _ref[1];
        }
      } else {
        fobj = {
          file: file
        };
      }
      if (!base) {
        base = fobj.base || "";
      }
      full = path.resolve(base, file);
      return fs.stat(full, function(err, stat) {
        try {
          if (err || !stat || !stat.isFile()) {
            return next();
          }
          fobj.base = base;
          _.defaults(fobj, {
            name: path.basename(file)
          });
          return fs.readFile(full, function(err, data) {
            try {
              if (err || !data) {
                return next();
              }
              fobj.content = data;
              return _this.exec_load("compile", fobj, next);
            } catch (e) {
              return next(e);
            }
          });
        } catch (e) {
          return next(e);
        }
      });
    }
  ];
};