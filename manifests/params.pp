class openvmtools::params {
  # RHEL4 only has an glib2-2.4 version. We must stay with the latest
  # version which doesn't require glib2-2.6.
  $ovt_version = $::lsbmajdistrelease ? {
    '4'     => '2009.01.21-142982',
    '6'     => '2010.10.18-313025',
    default => '2009.07.22-179896',
  }
}
