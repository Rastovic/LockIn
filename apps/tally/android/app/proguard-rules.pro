# R8 keep rules for the release build.
#
# Everything here exists because something is looked up by reflection, which
# R8 cannot see. Nothing here is a workaround for a bug: reflection is the
# mechanism, and a keep rule is how you tell a shrinker about it.

# Room resolves a database's generated implementation with Class.forName on
# "<name>_Impl". Nothing references that class in bytecode, so R8 removes it
# and Room throws "Failed to create an instance of ..." on first use.
#
# This app does not use Room directly - play-services-ads pulls in WorkManager,
# which is Room-backed, and WorkManager initialises from an androidx.startup
# provider **before Flutter runs**. So the failure is a crash at launch, not a
# broken feature: the app never gets far enough to show anything.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# The ads SDK's offline ping worker is instantiated by name by WorkManager.
-keep class * extends androidx.work.Worker { <init>(...); }
-keep class * extends androidx.work.ListenableWorker { <init>(...); }
