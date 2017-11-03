/*-
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace PlayMyVideos.Widgets.Views {
    public class BoxesView : Gtk.Grid {
        PlayMyVideos.Services.LibraryManager library_manager;

        public signal void video_selected (Objects.Video video);

        Gtk.FlowBox boxes;
        Gtk.Revealer action_revealer;

        Widgets.Views.BoxView box_view;

        private string _filter = "";
        public string filter {
            get {
                return _filter;
            } set {
                if (_filter != value) {
                    _filter = value;
                    boxes.invalidate_filter ();
                }
            }
        }

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
            library_manager.added_new_box.connect ((box) => {
                Idle.add (() => {
                    add_box (box);
                });
            });
        }

        public BoxesView () {
            build_ui ();
        }

        private void build_ui () {
            boxes = new Gtk.FlowBox ();
            boxes.margin = 24;
            boxes.homogeneous = true;
            boxes.row_spacing = 12;
            boxes.column_spacing = 24;
            boxes.max_children_per_line = 24;
            boxes.valign = Gtk.Align.START;
            boxes.set_sort_func (boxes_sort_func);
            boxes.set_filter_func (boxes_filter_func);
            boxes.child_activated.connect (show_box_viewer);

            var boxes_scroll = new Gtk.ScrolledWindow (null, null);
            boxes_scroll.add (boxes);

            box_view = new Widgets.Views.BoxView ();
            box_view.video_selected.connect ((video) => { video_selected (video); });

            action_revealer = new Gtk.Revealer ();
            action_revealer.add (box_view);
            action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            var content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            content.expand = true;
            content.pack_start (boxes_scroll, true, true, 0);
            content.pack_start (action_revealer, false, false, 0);

            this.add (content);
            action_revealer.set_reveal_child (false);
        }

        public void add_box (Objects.Box box) {
            lock (boxes) {
                var b = new Widgets.Box (box);
                boxes.add (b);
            }
        }

        private void show_box_viewer (Gtk.FlowBoxChild item) {
            action_revealer.set_reveal_child (true);
            var box = (item as PlayMyVideos.Widgets.Box).box;
            box_view.show_box (box);
        }

        public void unselect_all () {
            boxes.unselect_all ();
            action_revealer.set_reveal_child (false);
        }

        private int boxes_sort_func (Gtk.FlowBoxChild child1, Gtk.FlowBoxChild child2) {
            var item1 = (PlayMyVideos.Widgets.Box)child1;
            var item2 = (PlayMyVideos.Widgets.Box)child2;
            if (item1 != null && item2 != null) {
                return item1.title.collate (item2.title);
            }
            return 0;
        }

        private bool boxes_filter_func (Gtk.FlowBoxChild child) {
            if (filter.strip ().length == 0) {
                return true;
            }

            string[] filter_elements = filter.strip ().down ().split (" ");
            var box = (child as Widgets.Box).box;

            foreach (string filter_element in filter_elements) {
                if (!box.title.down ().contains (filter_element)) {
                    bool video_title = false;
                    foreach (var video in box.videos) {
                        if (video.title.down ().contains (filter_element)) {
                            video_title = true;
                        }
                    }
                    if (video_title) {
                        continue;
                    }
                    return false;
                }
            }
            return true;
        }

        public void reset () {
            action_revealer.set_reveal_child (false);
            box_view.reset ();
            foreach (var child in boxes.get_children ()) {
                child.destroy ();
            }
        }
    }
}
