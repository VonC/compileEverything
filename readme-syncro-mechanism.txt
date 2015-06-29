This document describes the new synchro mechanism between the blessed server and the staging and external server.
The sync mode is per repository, i.e. not all the repositories have to share the same sync mode

1) Branch synchronization
a) The default mode
The default behaviour is as follows

 Blessed  Server        |    Staging Server        |   External Server
                        |                          |
master branch         ---->  master_hs* branch   ----> master_hs*
                        |                          |
master_ext branch     <-----  master_ext branch  <---- master branch
                        |                          |

Basically, from blessed server, only changes in master branch are sync'd to the external server on a branch called master_hs*i on the blessed server. From external server, only changes in master branch are sync'd to the blessed server on a branch called master_ext on that blessed server. Other branches are not sync'd

This default mode was what has been set initially. 
We have recently introduced two other way of synchronization.

b) The PARTIAL mode.
The master branches are sync'd as in the default behaviour described previously.
The branches with a suffix _sync will be sync'd as _sync_blessed from the blessed to the external server
and as _sync_external from the external to the blessedi server. Other branches are not synch'd.

 Blessed  Server          |     Staging Server         |   External Server
                          |                            |
master branch          -----> master_hs* branch      -----> master_hs*
                          |                            |
release1_sync branch   ----->  release1_sync_blessed  ---->   release1_sync_blessed
                          |                            |
master_ext branch      <----  master_ext branch      <---- master branch
                          |                            |
release1_sync_external  <---- release1_sync_external  <----  release1_sync
                          |                            |

This sync mode is activated by pushing a branch named "sync_mode_PARTIAL" on the repository  of the blessed server. 
(The master_ext branch must exist beforehand for the repo)


c) The FULL mode
The master branches are sync'd as in the default behaviour described previously.
Any other branch <branchname> is sync'd from blessed to external server as <branchname>_blessed.
Any other branch <branchname> is sync'd from external to blessed server as <branchname>_external.

 Blessed  Server          |     Staging Server         |   External Server
                          |                            |
master branch          ----> master_hs* branch     ----> master_hs*
                          |                            |
release1 branch        ---->  release1_blessed      ---->   release1_blessed
                          |                            |
master_ext branch      <----  master_ext branch    <---- master branch
                          |                            |
release1_external      <---- release1_external      <----  release1
                          |                            |


2) Pulling changes from external
In order to deal with scalability, the pull_external was also changed.
Instead of trying to fetch all existing repositories on the external server, the pull_external script will 
check the existence of files in the shippingbay/outgoing of the external server and perform a fetch on the required repo only.
The shippingbay/outgoing is populated by the post-update hook and will contain the name of the repo and the name of the branch.
The pull_external script will perform a fetch on the branch of the repository referred by the file in shippingbay/outgoing and then generate a file with the same name in shippingbay/incoming on the external server. A job on the external server would then cleanup the files in shippingbay/incoming and shippingbay/outgoing, so that the pull script does not keep on trying to fetch on a repository that has been already fetched.. 
