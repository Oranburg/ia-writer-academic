/* =========================================================
   ORANBURG STYLE — TEMPLATE SCRIPT
   Seth C. Oranburg

   iA Writer replaces the innerHTML of <body data-document>
   and then dispatches an "ia-writer-change" event on that
   element (it does not bubble). This script runs once on
   load and again after every such event. Every step is
   idempotent, because the next keystroke brings fresh HTML.

   What it does, all of it optional per template through
   attributes on <body>:
   1. Footnote references: normalizes the "[1]" form some
      iA Writer code paths emit into a superscript.
   2. Citations (data-oranburg-citations="inline"): puts the
      full text of a [#CiteKey]: definition where iA Writer
      prints "[2]", and hides the duplicate list entry.
   3. Headings (data-oranburg-outline="legal"): marks
      Abstract, Contents, Introduction, Conclusion and
      similar headings .unnumbered, marks headings that
      already carry a typed number .self-numbered, marks the
      first H1 .doc-title, and writes the legal outline
      number (I, A, 1, i, a) onto {{TOC}} links.
   4. Law of the Firm boxes: an H4 starting with 📜, 💡 or
      📄 and the blockquote after it get box-* classes.
   5. Hebrew and Aramaic (Conventions/hebrew-sources.md):
      marks any block whose first strong character is Hebrew,
      groups a Tier 2 teaching block, marks the citation line
      under a Tier 1 quotation, and boxes the flag strings.
   6. Title page: fills the author when iA Writer has none.

   Shared source: shared/oranburg.js. tools/build.py copies it
   into each bundle.
   ========================================================= */
(function () {
    "use strict";

    var DEFAULT_AUTHOR = "Seth C. Oranburg";

    var STRUCTURAL = /^(abstract|contents|table of contents|introduction|conclusion|acknowledg(e)?ments?|appendix(\b.*)?|epigraph|preface|foreword|summary)$/i;

    var SELF_NUMBERED = /^\s*(?:part\s+)?(?:[IVXLC]+|[A-Z]|\d+|[ivxlc]+|[a-z])[.)]\s+/;

    var BOXES = [
        { mark: "\uD83D\uDCDC", name: "source" },       // 📜
        { mark: "\uD83D\uDCA1", name: "insight" },      // 💡
        { mark: "\uD83D\uDCC4", name: "transaction" }   // 📄
    ];

    function each(list, fn) {
        Array.prototype.forEach.call(list, fn);
    }

    function headingText(h) {
        return (h.textContent || "").replace(/\s+/g, " ").replace(/[.:\s]+$/, "").trim();
    }

    /* 1. Footnote references ------------------------------------------ */
    function normalizeFootnoteRefs(root) {
        each(root.querySelectorAll("a.footnote"), function (a) {
            var m = /^\s*\[(\d+)\]\s*$/.exec(a.textContent || "");
            if (m) {
                a.textContent = m[1];
            }
            if (!a.parentElement || a.parentElement.tagName !== "SUP") {
                var sup = document.createElement("sup");
                a.parentNode.insertBefore(sup, a);
                sup.appendChild(a);
            }
        });
    }

    /* 2. Citations ----------------------------------------------------- */
    function citationEntry(root, href) {
        if (!href || href.charAt(0) !== "#") {
            return null;
        }
        var id = decodeURIComponent(href.slice(1));
        var li = document.getElementById(id);
        return li && root.contains(li) ? li : null;
    }

    function citationHTML(li) {
        var clone = li.cloneNode(true);
        each(clone.querySelectorAll(".citekey, .reversefootnote"), function (n) {
            n.parentNode.removeChild(n);
        });
        var ps = clone.querySelectorAll("p");
        var html = ps.length ? Array.prototype.map.call(ps, function (p) {
            return p.innerHTML;
        }).join(" ") : clone.innerHTML;
        // Drop the terminal period: the footnote supplies its own punctuation.
        return html.replace(/\s+$/, "").replace(/\.$/, "");
    }

    function inlineCitations(root) {
        each(root.querySelectorAll("a.citation"), function (a) {
            if (a.getAttribute("data-oranburg-cite") === "done") {
                return;
            }
            var li = citationEntry(root, a.getAttribute("href"));
            if (!li) {
                return;
            }
            var locator = a.querySelector(".locator");
            var key = a.querySelector(".citekey");
            var html = '<span class="cite-text">' + citationHTML(li) + "</span>";
            if (locator && locator.textContent.trim()) {
                html += ', <span class="locator">' + locator.innerHTML + "</span>";
            }
            a.innerHTML = html;
            if (key) {
                a.appendChild(key);
            }
            a.setAttribute("data-oranburg-cite", "done");
            li.classList.add("oranburg-inlined");
        });
    }

    /* 3. Headings and outline ----------------------------------------- */
    var ROMAN = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"],
                 [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"],
                 [5, "V"], [4, "IV"], [1, "I"]];

    function roman(n) {
        var out = "";
        ROMAN.forEach(function (p) {
            while (n >= p[0]) { out += p[1]; n -= p[0]; }
        });
        return out;
    }

    function alpha(n) {
        var out = "";
        while (n > 0) {
            n -= 1;
            out = String.fromCharCode(65 + (n % 26)) + out;
            n = Math.floor(n / 26);
        }
        return out;
    }

    var FORMATS = [
        function (n) { return roman(n) + "."; },
        function (n) { return alpha(n) + "."; },
        function (n) { return n + "."; },
        function (n) { return roman(n).toLowerCase() + "."; },
        function (n) { return alpha(n).toLowerCase() + "."; }
    ];

    /* The deck is a paragraph whose whole text is one <em>. The byline
       is the short paragraph straight after the title or the deck.
       Checked on text, not markup, so a body paragraph that merely
       contains an italic phrase is never taken for either. */
    function markFrontMatter(title) {
        var p = title.nextElementSibling;
        if (p && p.tagName === "P") {
            var em = p.children.length === 1 ? p.children[0] : null;
            if (em && em.tagName === "EM" &&
                    em.textContent.trim() === p.textContent.trim()) {
                p.classList.add("deck");
                p = p.nextElementSibling;
            }
        }
        if (p && p.tagName === "P" && p.children.length === 0 &&
                p.textContent.trim().split(/\s+/).length <= 8) {
            p.classList.add("byline");
        }
    }

    function markHeadings(root, legal) {
        var headings = root.querySelectorAll("h1, h2, h3, h4, h5, h6");
        var firstH1 = root.querySelector(":scope > h1");
        if (firstH1) {
            firstH1.classList.add("doc-title");
            markFrontMatter(firstH1);
        }
        if (!legal) {
            return;
        }
        var counters = [0, 0, 0, 0, 0];
        each(headings, function (h) {
            var level = parseInt(h.tagName.charAt(1), 10);
            var text = headingText(h);
            if (h === firstH1 || h.classList.contains("box-title")) {
                return;
            }
            if (level <= 2 && STRUCTURAL.test(text)) {
                h.classList.add("unnumbered");
                if (/^(table of )?contents$/i.test(text)) {
                    h.classList.add("contents-heading");
                }
                for (var j = level - 1; j < 5; j++) { counters[j] = 0; }
                return;
            }
            if (SELF_NUMBERED.test(text)) {
                h.classList.add("self-numbered");
            }
            if (level > 5) {
                return;
            }
            counters[level - 1] += 1;
            for (var k = level; k < 5; k++) { counters[k] = 0; }
            h.setAttribute("data-outline", FORMATS[level - 1](counters[level - 1]));
        });
    }

    function numberTOC(root) {
        var byText = {};
        each(root.querySelectorAll("h1, h2, h3, h4, h5, h6"), function (h) {
            var t = headingText(h);
            if (!(t in byText)) { byText[t] = h; }
        });
        each(root.querySelectorAll(".TOC a"), function (a) {
            var href = a.getAttribute("href") || "";
            var target = href.charAt(0) === "#"
                ? document.getElementById(decodeURIComponent(href.slice(1))) : null;
            if (!target) {
                target = byText[headingText(a)] || null;
            }
            var outline = target && !target.classList.contains("self-numbered")
                ? target.getAttribute("data-outline") : null;
            if (outline) {
                a.setAttribute("data-outline", outline);
            } else {
                a.removeAttribute("data-outline");
            }
            a.classList.toggle("toc-doc-title", !!target && target.classList.contains("doc-title"));
            /* A box is not a section, and the Contents heading does
               not list itself. */
            a.classList.toggle("toc-omit", !!target && (
                target.classList.contains("box-title") ||
                target.classList.contains("contents-heading") ||
                /^(table of )?contents$/i.test(headingText(a))));
        });
    }

    /* 3b. The swallowed-title warning ---------------------------------
       Every template treats the first H1 as the document title:
       centered, unnumbered, left out of the Contents. A file that
       opens with a section heading instead of the article title
       therefore loses that section, and the outline starts at I on
       the second one. The mistake is silent in print, so it is
       named on screen. */
    function warnOnSwallowedTitle(root) {
        var existing = root.querySelector(".oranburg-warning");
        var firstH1 = root.querySelector(":scope > h1");
        var swallowed = firstH1 && STRUCTURAL.test(headingText(firstH1));
        if (!swallowed) {
            if (existing) { existing.parentNode.removeChild(existing); }
            return;
        }
        if (existing) { return; }
        var div = document.createElement("div");
        div.className = "oranburg-warning";
        div.textContent = "\u201C" + headingText(firstH1) + "\u201D is the first " +
            "heading in this file, so the template is treating it as the article " +
            "title: it is centered, it is not numbered, and it is left out of the " +
            "Contents. Put the article title above it as its own # heading.";
        firstH1.parentNode.insertBefore(div, firstH1);
    }

    /* 4. Hebrew and Aramaic -------------------------------------------- */

    /* Hebrew and Aramaic letters, presentation forms, and the
       numeral-like alef/bet/gimel signs. */
    var HEB = /[\u0590-\u05FF\uFB1D-\uFB4F]/;

    /* The first character with a strong direction, which is what
       Unicode bidi uses to set a paragraph's direction. Latin,
       Greek and Cyrillic are strong left to right; the Hebrew
       block is strong right to left. Marks, digits, spaces and
       punctuation are skipped. */
    var STRONG_LTR = /[A-Za-z\u00C0-\u024F\u0370-\u03FF\u0400-\u04FF]/;

    function firstStrongIsHebrew(el) {
        var text = el.textContent || "";
        for (var i = 0; i < text.length; i++) {
            var c = text.charAt(i);
            if (HEB.test(c)) { return true; }
            if (STRONG_LTR.test(c)) { return false; }
        }
        return false;
    }

    /* Conventions/hebrew-sources.md defines these as exact search
       targets. The pattern matches the whole bracketed string so a
       flag carrying its own argument still boxes. */
    var FLAG_RE = new RegExp(
        "\\[(?:Aramaic|Mixed register: needs human|Editorial nikud: verify" +
        "|Vocalization:[^\\]]*|Gloss pending|Unverified: no corpus hit" +
        "|Not fetched:[^\\]]*)\\]", "g");

    function markHebrewFlags(root) {
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
        var targets = [], node;
        while ((node = walker.nextNode())) {
            if (node.parentElement && node.parentElement.closest(".heb-flag")) {
                continue;
            }
            FLAG_RE.lastIndex = 0;
            if (FLAG_RE.test(node.nodeValue || "")) {
                targets.push(node);
            }
        }
        targets.forEach(function (t) {
            var frag = document.createDocumentFragment();
            var text = t.nodeValue, last = 0, m;
            FLAG_RE.lastIndex = 0;
            while ((m = FLAG_RE.exec(text))) {
                if (m.index > last) {
                    frag.appendChild(document.createTextNode(text.slice(last, m.index)));
                }
                var span = document.createElement("span");
                span.className = "heb-flag";
                if (m[0] === "[Aramaic]") {
                    span.className += " heb-flag-label";   // a label, not a defect
                }
                span.textContent = m[0];
                frag.appendChild(span);
                last = m.index + m[0].length;
            }
            if (last < text.length) {
                frag.appendChild(document.createTextNode(text.slice(last)));
            }
            t.parentNode.replaceChild(frag, t);
        });
    }

    /* A paragraph holding one <em> and nothing else: the
       romanization line of a Tier 2 teaching block. */
    function isAllItalic(p) {
        if (!p || p.tagName !== "P") { return false; }
        var kids = Array.prototype.filter.call(p.childNodes, function (n) {
            return n.nodeType !== 3 || (n.nodeValue || "").trim() !== "";
        });
        return kids.length === 1 && kids[0].nodeType === 1 &&
               (kids[0].tagName === "EM" || kids[0].tagName === "I");
    }

    function isGloss(p) {
        if (!p || p.tagName !== "P") { return false; }
        return /^\s*["\u201C\u2018'(]/.test(p.textContent || "");
    }

    /* Italic text on its own line, used as the citation and
       edition under a Tier 1 quotation. */
    function isCitationLine(p) {
        if (!p || p.tagName !== "P") { return false; }
        var t = (p.textContent || "").trim();
        return t.length > 0 && t.length < 300 && p.querySelector("em, i") !== null;
    }

    function markHebrew(root) {
        /* Direction and leading, for every block that starts Hebrew */
        each(root.querySelectorAll("p, blockquote, li, td, th, h1, h2, h3, h4, h5, h6"),
            function (el) {
                el.classList.toggle("hebrew-block", firstStrongIsHebrew(el));
            });

        /* Tier 1: Hebrew blockquote, English blockquote, citation */
        each(root.querySelectorAll("blockquote.hebrew-block"), function (bq) {
            var english = bq.nextElementSibling;
            var cite = english && english.tagName === "BLOCKQUOTE"
                ? english.nextElementSibling : bq.nextElementSibling;
            if (cite && isCitationLine(cite) && !cite.classList.contains("hebrew-block")) {
                cite.classList.add("source-citation");
            }
        });

        /* Tier 2: Hebrew line, romanization, gloss */
        each(root.querySelectorAll("p.hebrew-block"), function (heb) {
            if (heb.parentElement && heb.parentElement.tagName === "BLOCKQUOTE") {
                return;
            }
            var translit = heb.nextElementSibling;
            if (!isAllItalic(translit)) {
                return;
            }
            var gloss = translit.nextElementSibling;
            heb.classList.add("tier2", "tier2-hebrew");
            translit.classList.add("tier2", "tier2-translit");
            if (isGloss(gloss)) {
                gloss.classList.add("tier2", "tier2-gloss");
            } else {
                translit.classList.add("tier2-gloss");   /* closes the unit */
            }
        });

        markHebrewFlags(root);
    }

    /* 5. Law of the Firm boxes ---------------------------------------- */
    function markBoxes(root) {
        each(root.querySelectorAll("h4"), function (h) {
            var text = (h.textContent || "").trim();
            BOXES.forEach(function (box) {
                if (text.indexOf(box.mark) !== 0) {
                    return;
                }
                h.classList.add("box-title", "box-" + box.name);
                var next = h.nextElementSibling;
                if (next && next.tagName === "BLOCKQUOTE") {
                    next.classList.add("box-body", "box-" + box.name);
                }
            });
        });
    }

    /* 6. Title page author ---------------------------------------------- */
    function fillAuthor() {
        each(document.querySelectorAll("[data-author]"), function (el) {
            if (!(el.textContent || "").replace(/ /g, " ").trim()) {
                el.textContent = el.getAttribute("data-oranburg-default-author") || DEFAULT_AUTHOR;
            }
        });
    }

    /* Driver ----------------------------------------------------------- */
    /* Notes go under the author's Notes heading. iA Writer and pandoc
       both append footnotes after everything else in the document, so
       a source that writes "## Notes" and then "## Web sources" printed
       an empty Notes heading over the web sources, and then the notes
       themselves with no heading at all. Where the document has a
       heading reading Notes or Endnotes, move the notes to sit directly
       under it. Idempotent: iA Writer re-runs this on every change. */
    function placeNotes(root) {
        var notes = root.querySelector(".footnotes");
        if (!notes) { return; }
        var heads = root.querySelectorAll("h1, h2, h3");
        var home = null;
        each(heads, function (h) {
            if (!home && /^\s*(end)?notes\s*$/i.test(h.textContent)) { home = h; }
        });
        if (!home || home.nextElementSibling === notes) { return; }
        home.parentNode.insertBefore(notes, home.nextSibling);
        notes.classList.add("notes-placed");
    }

    function run() {
        var root = document.querySelector("[data-document]");
        if (root) {
            try {
                normalizeFootnoteRefs(root);
                if (root.getAttribute("data-oranburg-citations") === "inline") {
                    inlineCitations(root);
                }
                markBoxes(root);
                markHeadings(root, root.getAttribute("data-oranburg-outline") === "legal");
                markHebrew(root);
                numberTOC(root);
                warnOnSwallowedTitle(root);
                placeNotes(root);
            } catch (e) {
                if (window.console) { console.error("oranburg.js", e); }
            }
        }
        fillAuthor();
    }

    function attach() {
        var root = document.querySelector("[data-document]");
        if (root) {
            root.addEventListener("ia-writer-change", run);
        }
        each(document.querySelectorAll("[data-author]"), function (el) {
            el.addEventListener("ia-writer-change", fillAuthor);
        });
        run();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", attach);
    } else {
        attach();
    }

    window.Oranburg = { run: run };
})();
