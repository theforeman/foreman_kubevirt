### 0.1.7 / 2019-11-11

* Add kubevirt API version to readme (#124)
* Use v1alpha3 version (#123)

### 0.1.6 / 2019-09-24

* Fixes #27929 - Fix capacity validation to work only on kubevirt CR (#121)

### 0.1.5 / 2019-08-27

* bump fog kubevirt version to 1.3.2 (#119)
* Fixes #27684 - Add validation for PVC (#117)
* Fixes #27703- Add validation for capacity in profile (#118)
* Fixes #27655 - fix cores to cpu_cores in the api documention (#116)
* Fixes #27320 - Add support for vnc console (#111)
* Fixes #27543 - Remove refresh_cache button (#114)
* Fixes #27494 - Fix validation and test_connection (#113)
* Fix update api params in kubevirt (#112)

### 0.1.4 / 2019-06-30

*  Align values to expected format
*  Fixes #27189 - change the token to be required in save/test validation

### 0.1.3 / 2019-05-15

* Support User Data (#103)
* Fix #26784: Create VM with image only should pass (#102)
* Fixes #26656 - Fix memory issues (#100)
* Add compute resource tests (#99)
* Add tests for default values (#98)
* Add message expectation to tests (#97)

### 0.1.2 / 2019-04-30

* Clear assets precompile error
* Set license format as gem expects (#93)
* Refactor create vm (#92)
* Update getting-started.md (#90)
* Add more unit tests (#89)


### 0.1.1 / 2019-04-24

* Raise error in case of booting from volume and from image (#81)
* Update references to foreman org (#83)
* Fix bootable flag (#80)
* Fix Pod network element (#79)
* Add exception in case capacity is empty
* Support compute profiles (#76)
* Add link to plugin documentation (#77)

### 0.1.0 / 2019-04-17

* Initial release of `foreman_kubevirt` plugin. It provides common `kubevirt`
  management foreman capabilities.
