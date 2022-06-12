# File: /main.mk
# Project: mkpm-pkg
# File Created: 12-06-2022 09:16:04
# Author: Clay Risser
# -----
# Last Modified: 12-06-2022 09:16:30
# Modified By: Clay Risser
# -----
# Risser Labs LLC (c) Copyright 2021 - 2022
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEBUILD ?= debuild
DH_MAKE ?= dh_make
DPKG ?= dpkg
DPKG_BUILDPACKAGE ?= dpkg-buildpackage
RSYNC ?= rsync

PKG_GIT_CLEAN_FLAGS := -e !.upstream

.upstream/debian/control: $(call git_deps,.)
ifneq (1,$(PKG_STRICT))
	$(MAKE) -s pkg-deb/clean
endif
	@$(call copy_git,.upstream)
	@$(RM) -rf .upstream/debian
	@$(CD) .upstream && $(DH_MAKE) -p $(PKG_NAME)_$(PKG_VERSION) --createorig -s -y
	@if [ -d debian ]; then \
		$(RSYNC) -a debian/ .upstream/debian/; \
	fi

.PHONY: pkg-deb
pkg-deb: .upstream/debian/control
ifneq (1,$(PKG_STRICT))
	@export IS_PKG=1 && $(CD) .upstream && $(DPKG_BUILDPACKAGE) -b -uc -us
else
	@export IS_PKG=1 && $(CD) .upstream && $(DEBUILD) -d -uc -us
endif
	@$(MAKE) -s pkg-deb/inspect

.PHONY: pkg-deb/inspect
pkg-deb/inspect:
	@$(DPKG) -c $$($(ECHO) $$($(LS) $(PKG_NAME)_$(PKG_VERSION)-*_*.deb) | $(GREP) -oE '^[^ ]+')

.PHONY: pkg-deb/clean
pkg-deb/clean:
ifneq (1,$(PKG_STRICT))
	@$(RM) -rf .upstream
endif
ifneq (1,$(PKG_STRICT))
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION).orig.tar.xz
endif
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*_*.build
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*_*.buildinfo
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*_*.changes
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*_*.deb
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*.debian.tar.xz
	@$(RM) -f $(PKG_NAME)_$(PKG_VERSION)-*.dsc
	@$(RM) -f /tmp/$(PKG_NAME)_$(PKG_VERSION)-*.diff.*

define copy_git
$(MKDIR) -p $1 && \
for f in $$($(GIT) ls-files); do \
	export PARENT=$$($(ECHO) $$f | $(SED) 's|[^/]\+$$||g') && \
	if [ "$$PARENT" != "" ]; then \
		$(MKDIR) -p "$1/$$PARENT"; \
	fi && \
	$(CP) $$f $1/$$f; \
done
endef
