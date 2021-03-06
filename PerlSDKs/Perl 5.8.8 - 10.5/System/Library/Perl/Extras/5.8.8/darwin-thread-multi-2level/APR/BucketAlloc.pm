# 
# /*
#  * *********** WARNING **************
#  * This file generated by ModPerl::WrapXS/0.01
#  * Any changes made here will be lost
#  * ***********************************
#  * 01: lib/ModPerl/Code.pm:708
#  * 02: lib/ModPerl/WrapXS.pm:624
#  * 03: lib/ModPerl/WrapXS.pm:1173
#  * 04: Makefile.PL:423
#  * 05: Makefile.PL:325
#  * 06: Makefile.PL:56
#  */
# 


package APR::BucketAlloc;

use strict;
use warnings FATAL => 'all';


use APR ();
use APR::XSLoader ();
our $VERSION = '0.009000';
APR::XSLoader::load __PACKAGE__;



1;
__END__

=head1 NAME

APR::BucketAlloc - Perl API for Bucket Allocation




=head1 Synopsis

  use APR::BucketAlloc ();
  $ba = APR::BucketAlloc->new($pool);
  $ba->destroy;





=head1 Description

C<APR::BucketAlloc> is used for bucket allocation.






=head2 C<new>

Create an C<APR::BucketAlloc> object:

  $ba = APR::BucketAlloc->new($pool);

=over 4

=item class: C<APR::BucketAlloc>

=item arg1: C<$pool>
( C<L<APR::Pool object|docs::2.0::api::APR::Pool>> )

The pool used to create this object.

=item ret: C<$ba>
( C<L<APR::BucketAlloc object|docs::2.0::api::APR::BucketAlloc>> )

The new object.

=item since: 2.0.00

=back

This bucket allocation list (freelist) is used to create new buckets
(via C<L<APR::Bucket-E<gt>new|docs::2.0::api::APR::Bucket/C_new_>>)
and bucket brigades (via
C<L<APR::Brigade-E<gt>new|docs::2.0::api::APR::Brigade/C_new_>>).

You only need to use this method if you aren't running under httpd.
If you are running under mod_perl, you already have a bucket
allocation available via
C<L<$c-E<gt>bucket_alloc|docs::2.0::api::Apache2::Connection/C_bucket_alloc_>>
and
C<L<$bb-E<gt>bucket_alloc|docs::2.0::api::APR::Brigade/C_bucket_alloc_>>.

Example:

  use APR::BucketAlloc ();
  use APR::Pool ();
  my $ba = APR::BucketAlloc->(APR::Pool->pool);
  my $eos_b = APR::Bucket::eos_create($ba);






=head2 C<destroy>

Destroy an C<L<APR::BucketAlloc
object|docs::2.0::api::APR::BucketAlloc>>:

  $ba->destroy;

=over 4

=item arg1: C<$ba>
( C<L<APR::BucketAlloc object|docs::2.0::api::APR::BucketAlloc>> )

The freelist to destroy.

=item ret: no return value

=item since: 2.0.00

=back

Once destroyed this object may not be used again.

You need to destroy C<$ba> B<only> if you have created it via
C<L<APR::BucketAlloc-E<gt>new|/C_new_>>. If you try to destroy an
allocation not created by this method, you will get a segmentation
fault.

Moreover normally it is not necessary to destroy allocators, since the
pool which created them will destroy them during that pool's cleanup
phase.




=head1 See Also

L<mod_perl 2.0 documentation|docs::2.0::index>.




=head1 Copyright

mod_perl 2.0 and its core modules are copyrighted under
The Apache Software License, Version 2.0.




=head1 Authors

L<The mod_perl development team and numerous
contributors|about::contributors::people>.

=cut

