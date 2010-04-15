This is PageCaptain.

PageCaptain:

    ... is a web application designed to assist Scavenger Hunt
    teams or other large groups needing to efficiently manage
    large numbers of loosely related objectives.

    ... has deep roots in the annual University of Chicago
    Scavenger Hunt.
    
    ... is a local anarchy promotion technology that predates
    "social media" and "crowdsourcing".
    
    ... has been the core technology of the Federation of
    Independent Scavhunt Teams since its inception in 2002.

See INSTALL.txt for installation instructions.

CRASH COURSE

Once you have a working PageCaptain installation, the first step
is to populate it with users.  Each user should visit the new
user survey at survey.mhtml and follow the instructions there.  This
link is in the sidebar.

Superuser ("uber-tuber") abilities are needed to change certain
site settings, and multiple uber-tubers have to agree in order
to clear the item list for a new hunt.  If you followed the INSTALL
directions you should already be an uber-tuber.  Use the "User
Promotion" link on the userinfo.mhtml page (via TEAM PROFILES, usually)
to upgrade additional trusted users.

When the list is released it needs to be loaded into the database.
Sadly there is no all-purpose way to do this automatically, as such
lists tend to be distributed as print-outs and have no universal
format.  When list input is enabled, the "INPUT ITEMS" link
(jentry.mhtml) will appear in the sidebar for logged-in users.  It may
sound daunting, but it shouldn't take a team of a dozen people more
than half an hour to transcribe a 300-item list.

    However, contributions of code to e.g. OCR and parse scans of
    list pages are eagerly encouraged!

In the sidebar, "THE LIST" links to the list search page.  Individual
items can be selected by clicking on the item number.  Users can CLAIM
or WATCH items.  In both cases the item will show up on that user's
"DATABASE HQ" (index.mhtml) page, but for CLAIM the user will be
assigned responsibility for the item and gains extra options for
editing the item.

In particular, the items should be categorized (Roadtrip, Event, Craft,
etc.) and the point value confirmed (the system attempts to get this
from the scoring text, but can be wrong) to aid searching and
prioritizing.  As the hunt progresses, item status should be updated
(Help Wanted, Done, Impossible, etc) to provide visual feedback in
search results and the list grid view.

VERSION HISTORY

The software used by the FIST is, at least internally, called PageCaptain. This is because it was initially developed as a system to supplant the beaurocratic heirarchy of captains and page-captains typical of the old monolithic superteams (e.g. Shoreland, pre-collapse, and some would say, Palevsky in its current form), which those of a more independent bent came to realize only sapped the vitality and agility from otherwise powerful teams, and would surely crush a small, ad-hoc outfit.

PageCaptain (the system, not the model) is currently on its second major revision. The first, developed in 2000 but not successfully deployed within a team until the disastrous BJ-Mathews merger of 2001, was known generically as the ScavCode?, and was largely scrapped after the 2002 Hunt (at which point I, graduated, liberated from homework, and in a job where I interacted with cool technology on a daily basis, decided to overhaul the thing).

The revised system was first used to great success during the 2003 Hunt by LP3:FIST2:DP, and (counting extensive upgrades made in the course of that event, in response to the pressures of people actually using it) has undergone at least two minor rounds of revision since then. So one could say with some degree of accuracy that the Fist 2004 team ran on PageCaptain 2.3, since another round of revisions was developed shortly before the Hunt.

Between ScavHunt 2004 and 2005 I incorporated various changes hastily patched into the system during the Hunt (this happens every year), and later added AJAX-like features to facilitate inputting the List through a web interface. Fist 2005 (LP5:FIST4:DPRe:BSDSa:L_MU) thus used PageCaptain 2.5.

Similarly for 2006, various minor intra-Hunt updates will be properly integrated for an interstitial 2.6. The major change will be that PageCaptain moves to a notionally permanent home on UnrealCity, which is greatly facilitated by packaging the suite to put it under the auspices of the Debian package management system. I feel that a rearrangement of this magnitude merits a major version bump, so in 2006 version 3.0 will be used. 

    (Text from the F.I.S.T. wiki, last updated 2006)

PageCaptain is Copyright (C) Michael Milligan 2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010

    PageCaptain is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

