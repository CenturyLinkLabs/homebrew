require 'formula'

class Wireshark < Formula
  homepage 'http://www.wireshark.org'

  stable do
    url 'http://wiresharkdownloads.riverbed.com/wireshark/src/wireshark-1.10.6.tar.bz2'
    mirror 'http://www.wireshark.org/download/src/wireshark-1.10.6.tar.bz2'
    sha1 '081a2daf85e3257d7a2699e84a330712e3e5b9bb'

    # Removes SDK checks that prevent the build from working on CLT-only systems
    # Reported upstream: https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=9290
    patch :DATA
  end

  head do
    url 'https://code.wireshark.org/review/wireshark', :using => :git

    depends_on :autoconf
    depends_on :automake
    depends_on :libtool
  end

  devel do
    url 'http://wiresharkdownloads.riverbed.com/wireshark/src/wireshark-1.11.2.tar.bz2'
    sha1 'af2b03338819b300f621048398b49403675db49c'
  end

  option 'with-x', 'Include X11 support'
  option 'with-qt', 'Use QT for GUI instead of GTK+'
  option 'with-headers', 'Install Wireshark library headers for plug-in developemnt'

  depends_on 'pkg-config' => :build

  depends_on 'glib'
  depends_on 'gnutls'
  depends_on 'libgcrypt'

  depends_on 'geoip' => :recommended

  depends_on 'c-ares' => :optional
  depends_on 'lua' => :optional
  depends_on 'pcre' => :optional
  depends_on 'portaudio' => :optional
  depends_on 'qt' => :optional

  if build.with? 'x'
    depends_on :x11
    depends_on 'gtk+'
  end

  def install
    system "./autogen.sh" if build.head?

    args = ["--disable-dependency-tracking",
            "--prefix=#{prefix}",
            "--with-gnutls",
            "--with-ssl"]

    args << "--disable-warnings-as-errors" if build.head?
    args << "--disable-wireshark" if build.without?("x") && build.without?("qt")
    args << "--disable-gtktest" if build.without? "x"
    args << "--with-qt" if build.with? "qt"

    system "./configure", *args
    system "make"
    ENV.deparallelize # parallel install fails
    system "make install"

    if build.with? 'headers'
      (include/"wireshark").install Dir["*.h"]
      (include/"wireshark/epan").install Dir["epan/*.h"]
      (include/"wireshark/epan/crypt").install Dir["epan/crypt/*.h"]
      (include/"wireshark/epan/dfilter").install Dir["epan/dfilter/*.h"]
      (include/"wireshark/epan/dissectors").install Dir["epan/dissectors/*.h"]
      (include/"wireshark/epan/ftypes").install Dir["epan/ftypes/*.h"]
      (include/"wireshark/epan/wmem").install Dir["epan/wmem/*.h"]
      (include/"wireshark/wiretap").install Dir["wiretap/*.h"]
      (include/"wireshark/wsutil").install Dir["wsutil/*.h"]
    end
  end

  def caveats; <<-EOS.undent
    If your list of available capture interfaces is empty
    (default OS X behavior), try the following commands:

      curl https://bugs.wireshark.org/bugzilla/attachment.cgi?id=3373 -o ChmodBPF.tar.gz
      tar zxvf ChmodBPF.tar.gz
      open ChmodBPF/Install\\ ChmodBPF.app

    This adds a launch daemon that changes the permissions of your BPF
    devices so that all users in the 'admin' group - all users with
    'Allow user to administer this computer' turned on - have both read
    and write access to those devices.

    See bug report:
      https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=3760
    EOS
  end

  test do
    system "#{bin}/randpkt", "-b", "100", "-c", "2", "capture.pcap"
    output = `#{bin}/capinfos -Tmc capture.pcap`
    assert_equal "File name,Number of packets\ncapture.pcap,2\n", output
  end
end

__END__
diff --git a/configure b/configure
index cd41b63..c473fe7 100755
--- a/configure
+++ b/configure
@@ -16703,42 +16703,12 @@ $as_echo "yes" >&6; }
 				break
 			fi
 		done
-		if test -z "$SDKPATH"
-		then
-			{ $as_echo "$as_me:${as_lineno-$LINENO}: result: no" >&5
-$as_echo "no" >&6; }
-			as_fn_error $? "We couldn't find the SDK for OS X $deploy_target" "$LINENO" 5
-		fi
 		{ $as_echo "$as_me:${as_lineno-$LINENO}: result: yes" >&5
 $as_echo "yes" >&6; }
 		;;
 	esac

 	#
-	# Add a -mmacosx-version-min flag to force tests that
-	# use the compiler, as well as the build itself, not to,
-	# for example, use compiler or linker features not supported
-	# by the minimum targeted version of the OS.
-	#
-	# Add an -isysroot flag to use the SDK.
-	#
-	CFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $CFLAGS"
-	CXXFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $CXXFLAGS"
-	LDFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $LDFLAGS"
-
-	#
-	# Add a -sdkroot flag to use with osx-app.sh.
-	#
-	OSX_APP_FLAGS="-sdkroot $SDKPATH"
-
-	#
-	# XXX - do we need this to build the Wireshark wrapper?
-	# XXX - is this still necessary with the -mmacosx-version-min
-	# flag being set?
-	#
-	OSX_DEPLOY_TARGET="MACOSX_DEPLOYMENT_TARGET=$deploy_target"
-
-	#
 	# In the installer package XML file, give the deployment target
 	# as the minimum version.
 	#

