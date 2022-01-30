;;; wgsl-mode.el --- major mode for WebGPU Shading Language

;; Copyright (C) 2022 κeen
;;
;; Authors: κeen
;; Keywords: languages WGSL GPU WebGPU

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for editing WGSL, a shader language for WebGPU.
;; This provides only a naive syntax highlighting and
;; the major mode hook.




;;; Code:

(provide 'wgsl-mode)

(defgroup wgsl nil
  "Major mode for WebGPU Shading Language"
  :group 'languages)

(defvar wgsl-mode-hook nil "WGSL mode hook")

(defvar wgsl-type-face 'wgsl-type-face)
(defface wgsl-type-face
  '((t (:inherit font-lock-type-face))) "wgsl: type face"
  :group 'wgsl)

(defvar wgsl-builtin-face 'wgsl-builtin-face)
(defface wgsl-builtin-face
  '((t (:inherit font-lock-builtin-face))) "wgsl: builtin face"
  :group 'wgsl)

(defvar wgsl-keyword-face 'wgsl-keyword-face)
(defface wgsl-keyword-face
  '((t (:inherit font-lock-keyword-face))) "wgsl: keyword face"
  :group 'wgsl)

(defvar wgsl-variable-name-face 'wgsl-variable-name-face)
(defface wgsl-variable-name-face
  '((t (:inherit font-lock-variable-name-face))) "wgsl: variable face"
  :group 'wgsl)

(defvar wgsl-reserved-words-face 'wgsl-reserved-words-face)
(defface wgsl-reserved-words-face
  '((t (:inherit wgsl-keyword-face))) "wgsl: reserved words face"
  :group 'wgsl)

(defvar wgsl-attribute-face 'wgsl-attribute-face)
(defface wgsl-attribute-face
  '((t (:inherit font-lock-preprocessor-face))) "wgsl: attribute face"
  :group 'wgsl)

(defvar wgsl-mode-hook nil)

(defvar wgsl-mode-map (make-sparse-keymap) "Keymap for WGSL major mode.")

;;;###autoload
(progn (add-to-list 'auto-mode-alist '("\\.wgsl\\'" . wgsl-mode)))

(eval-and-compile
  ;; These vars are useful for completion so keep them around after
  ;; compile as well. The goal here is to have the byte compiled code
  ;; have optimized regexps so its not done at eval time.
  (defvar wgsl-type-defining-keywords
    '("array" "atomic" "bool" "f32" "i32"
      "mat2x2" "mat2x3" "mat2x4"
      "mat3x2" "mat3x3" "mat3x4"
      "mat4x2" "mat4x3" "mat4x4"
      "override" "ptr" "sampler" "sampler_comparison" "struct"
      "texture1d" "texture2d" "texture2d_array" "texture_multisampled_2d"
      "texture_storage_1d" "texture_storage_2d" "texture_storage_2d_array" "texture_storage_3d"
      "texture_depth_2d" "texture_depth_2d_array" "texture_depth_cube" "texture_depth_cube_array" "texture_depth_multisampled_2d"
      "u32" "vec2" "vec3" "vec4"))
  (defvar wgsl-other-keywords
    '("bitcast" "break" "case" "continue" "continuing" "default" "discard" "else"
      "enable" "fallthrough" "false" "fn" "for" "function" "if" "let" "loop" "private"
      "return" "storage" "switch" "true" "type" "uniform" "var" "workgroup"))
  (defvar wgsl-reserved-words
    '("asm" "bf16" "const" "do" "enum" "f16" "f64" "handle" "i8" "i16" "i64"
      "mat" "premerge" "regardless" "typedef" "u8" "u16" "u64" "unless" "using" "vec" "void" "while"))

  (defvar wgsl-syntactic-tokens
    '("&" "&&" "->" "@" "/" "!" "[" "]" "{" "}" ":" "," "=" "==" "!=" ">"
      ">=" ">>" "<" "<=" "<<" "%" "-" "--" "." "+" "++" "|" "||" "(" ")" ";"
      "*" "~" "_" "^" "+=" "-=" "*=" "/=" "%=" "&=" "|=" "^=" ">>=" "<<="))
  (defvar wgsl-built-in-values
    '("vertex_index" "instance_index" "position" "position" "front_facing"
      "frag_depth" "local_invocation_id" "local_invocation_index" "global_invocation_id"
      "workgroup_id" "num_workgroups" "sample_index" "sample_mask" "sample_mask"))
  (defvar wgsl-built-in-functions
    '(
      "all" "any" "select" "arrayLength" "abs" "acos" "asin" "atan" "atan2"
      "ceil" "clamp" "cos" "cosh" "cross" "degrees" "distance" "exp" "exp2"
      "faceForward" "floor" "fma" "fract" "frexp" "inverseSqrt" "ldexp"
      "length" "log" "log2" "max" "min" "mix" "modf" "normalize" "pow"
      "quantizeToF16" "radians" "reflect" "round" "sign" "sin" "sinh"
      "smoothStep" "sqrt" "step" "tan" "tanh" "trunc"

      ; "abs" "clamp"
      "countLeadingZeros" "countOneBits" "countTrailingZeros"
      "firstBitHigh" "firstBitHigh" "firstBitLow" "extractBits" "extractBits"
      "insertBits" ; "max" "min"
      "reverseBits"

      "determinant" "transpose"

      "dot"

      "dpdx" "dpdxCoarse" "dpdxFine" "dpdy" "dpdyCoarse" "dpdyFine"
      "fwidth" "fwidthCoarse" "fwidthFine"

      "textureDimensions"

      "textureGather" "textureGatherCompare" "textureLoad" "textureNumLayers"
      "textureNumLevels" "textureNumSamples" "textureSample" "textureSampleBias"
      "textureSampleCompare" "textureSampleCompareLevel" "textureSampleGrad"
      "textureSampleLevel" "textureStore"


      "atomicLoad" "atomicStore" "atomicAdd" "atomicSub"
      "atomicMax" "atomicMin" "atomicAnd" "atomicOr" "atomicXor"
      "atomicExchange" "atomicCompareExchangeWeak"

      "pack4x8snorm" "pack4x8unorm" "pack2x16snorm" "pack2x16unorm" "pack2x16float"

      "unpack4x8snorm" "unpack4x8unorm" "unpack2x16snorm" "unpack2x16unorm" "unpack2x16float"

      "storageBarrier" "workgroupBarrier"
      ))
  (defvar wgsl-attribute-regex
    (let ((wgsl-identifiers-regex "\\(\\([a-zA-Z_][0-9a-zA-Z][0-9a-zA-Z_]*\\)\\|\\([a-zA-Z][0-9a-zA-Z_]*\\)\\)"))
                                        ; not exact, but works at some level
      (format  "@%s([^)]+)" wgsl-identifiers-regex))))

(eval-and-compile
  (defun wgsl-ppre (re)
    (format "\\<\\(%s\\)\\>" (regexp-opt re))))

(defvar wgsl-font-lock-keywords-1
  (append
   (list
    (cons (eval-when-compile wgsl-attribute-regex)
          wgsl-attribute-face)
    (cons (eval-when-compile
            (wgsl-ppre wgsl-type-defining-keywords))
          wgsl-type-face)
    (cons (eval-when-compile
            (wgsl-ppre wgsl-reserved-words))
          wgsl-reserved-words-face)
    (cons (eval-when-compile
            (wgsl-ppre wgsl-other-keywords))
          wgsl-keyword-face)
    (cons (eval-when-compile
            (wgsl-ppre wgsl-built-in-values))
          wgsl-builtin-face)
    (cons (eval-when-compile
            (wgsl-ppre wgsl-built-in-functions))
          wgsl-builtin-face))

   )
  "Highlighting expressions for WGSL mode.")


(defvar wgsl-font-lock-keywords wgsl-font-lock-keywords-1
  "Default highlighting expressions for WGSL mode.")

(defvar wgsl-mode-syntax-table
  (let ((wgsl-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" wgsl-mode-syntax-table)
    (modify-syntax-entry ?* ". 23" wgsl-mode-syntax-table)
    (modify-syntax-entry ?\n "> b" wgsl-mode-syntax-table)
    (modify-syntax-entry ?_ "w" wgsl-mode-syntax-table)
    wgsl-mode-syntax-table)
  "Syntax table for wgsl-mode.")


(defun wgsl-man-completion-list ()
  "Return list of all WGSL keywords."
  (append wgsl-builtin-list wgsl-deprecated-builtin-list))

;;;###autoload
(define-derived-mode wgsl-mode prog-mode "WGSL"
  "Major mode for editing WGSL shader files."
  (set (make-local-variable 'font-lock-defaults) '(wgsl-font-lock-keywords))
  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-padding) "")
  (run-mode-hooks 'wgsl-mode-hook))

;;; wgsl-mode.el ends here
