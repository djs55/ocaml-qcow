(*
 * Copyright (C) 2015 David Scott <dave@recoil.org>
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
module Error = Qcow_error
module Header = Qcow_header

module Make(B: Qcow_s.RESIZABLE_BLOCK) : sig
  include V1_LWT.BLOCK

  type discard = {
    journal: B.t;  (** A device containing journal for discard operations *)
  }
  (** discard (aka TRIM/UNMAP) configuration *)

  val create: ?discard:discard -> B.t -> size:int64 -> ?lazy_refcounts:bool -> unit
      -> [ `Ok of t | `Error of error ] io
  (** [create ?discard block ~size ?lazy_refcounts ()] initialises a qcow-formatted
      image on [block] with virtual size [size] in bytes. By default the file
      will use lazy refcounts, but this can be overriden by supplying
      [~lazy_refcounts:false]. By default the device will not support discard
      but this can be overriden by supplying a discard configuration. *)

  val connect: ?discard:discard -> B.t -> [ `Ok of t | `Error of error ] io
  (** [connect ?discard block] connects to an existing qcow-formatted image on
      [block]. By default the device will not support discard but this can be
      overriden by supplying a discard configuration. *)

  val resize: t -> new_size:int64 -> ?ignore_data_loss:bool -> unit -> [ `Ok of unit | `Error of error ] io
  (** [resize block new_size_bytes ?ignore_data_loss] changes the size of the
      qcow-formatted image to [new_size_bytes], rounded up to the next allocation
      unit. This function will fail with an error if the new size would be
      smaller than the old size as this would cause data loss, unless the argument
      [?ignore_data_loss] is set to true. *)

  val compact: t -> [ `Ok of unit | `Error of error ] io
  (** [compact t ()] scans the disk for unused space and attempts to fill it
      and shrink the file. This is useful if the underlying block device doesn't
      support discard and we must emulate it. *)

  val discard: t -> sector:int64 -> n:int64 -> unit -> [ `Ok of unit | `Error of error ] io
  (** [discard sector n] signals that the [n] sectors starting at [sector]
      are no longer needed and the contents may be discarded. Note the contents
      may not actually be deleted: this is not a "secure erase". *)

  val seek_unmapped: t -> int64 -> [ `Ok of int64 | `Error of error ] io
  (** [seek_unmapped t start] returns the offset of the next "hole": a region
      of the device which is guaranteed to be full of zeroes (typically
      guaranteed because it is unmapped) *)

  val seek_mapped: t -> int64 -> [ `Ok of int64 | `Error of error ] io
  (** [seek_mapped t start] returns the offset of the next region of the
      device which may have data in it (typically this is the next mapped
      region) *)

  val rebuild_refcount_table: t -> [ `Ok of unit | `Error of error ] io
  (** [rebuild_refcount_table t] rebuilds the refcount table from scratch.
      Normally we won't update the refcount table live, for performance. *)

  val header: t -> Header.t
  (** Return a snapshot of the current header *)

  module Debug: Qcow_s.DEBUG
    with type t = t
     and type error = error
end
