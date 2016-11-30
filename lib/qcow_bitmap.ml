(*
 * Copyright (C) 2016 David Scott <dave@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

type t = Cstruct.t

let make n =
  let bytes_required = (n + 7) / 8 in
  let result = Cstruct.create bytes_required in
  Cstruct.memset result 0;
  result

let set t n v =
  let i = n / 8 in
  let byte = Cstruct.get_uint8 t i in
  let byte' =
    if v
    then byte lor (1 lsl (n mod 8))
    else byte land (lnot (1 lsl (n mod 8))) in
  Cstruct.set_uint8 t i byte'

let get t n =
  let i = n / 8 in
  let byte = Cstruct.get_uint8 t i in
  byte land (1 lsl (n mod 8)) <> 0
