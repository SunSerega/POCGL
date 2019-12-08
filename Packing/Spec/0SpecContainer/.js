


/* ============================== *\
		   on page load
\* ============================== */

{
	
	let page_select = document.getElementById("page-select");
	let page_display = document.getElementById("page-display");
	let splitter = document.getElementById("splitter");
	
	let ww = window.innerWidth;
	let wh = window.innerHeight;
	
	for (let cont of document.getElementsByClassName("page-container"))
	{
		let par = cont.parentElement;
		par.update_cont = (w)=>{
			cont.style.width = w-15 + "px";
			cont.style.height = wh-15 + "px";
		};
	}
	
	let spl_X = ww * 0.30;
	const reset_spl = ()=>{
		ww = window.innerWidth;
		wh = window.innerHeight;
		
		page_select.style.height = wh + "px";
		splitter.style.height = wh + "px";
		page_display.style.height = wh + "px";
		
		if (ww-5<spl_X) spl_X = ww-5;
		if (spl_X<5) spl_X = 5;
		
		page_select.style.width = spl_X + "px";
		splitter.style.left = spl_X + "px";
		let x2 = spl_X+splitter.clientWidth;
		let w2 = ww - x2;
		page_display.style.left = x2 + "px";
		page_display.style.width = w2 + "px";
		
		page_select.update_cont(spl_X);
		page_display.update_cont(w2);
	}
	reset_spl();
	
	window.onresize = ()=>reset_spl();
	
	splitter.addEventListener("dblclick", ()=>{
		let w = 0;
		let psc = document.getElementsByClassName("page-container")[0];
		let psc2 = psc.children[0];
		for (let n of psc2.children)
			if (n.clientWidth>w) w = n.clientWidth;
		
		let get_margin = (el)=>{
			let style = el.currentStyle || window.getComputedStyle(el);
			return parseFloat(style.marginLeft) + parseFloat(style.marginRight);
		}
		
		spl_X = w +
			get_margin(psc) +
			get_margin(psc2)
		;
		reset_spl();
	});
	
	let spl_grabed = false;
	splitter.addEventListener("mousedown", (e)=>{
		spl_grabed=true;
		e.preventDefault();
	});
	window.addEventListener("mousemove", (e)=>{if (spl_grabed) {
		spl_X = e.clientX - splitter.clientWidth/2;
		reset_spl();
		e.preventDefault();
	}});
	window.addEventListener("mouseup", ()=>spl_grabed=false);
	
}

/* ============================== *\
		    page select
\* ============================== */

var root_folder = null;
var selected_page = null;

var currently_loading_folder = null;

const select_page = (new_page)=>{
	if (selected_page == new_page) return;
	fix_element(new_page);
	
	if (selected_page) {
		selected_page.hidden = true;
		let name_span = selected_page.name_span;
		if (name_span) name_span.style.backgroundColor = "inherit";
	}
	
	selected_page = new_page;
	if (selected_page)
	{
		selected_page.hidden = false;
		let name_span = selected_page.name_span;
		if (name_span) name_span.style.backgroundColor = "#D0D0D0";
		
		let tree_obj = new_page.tree_obj.root;
		while (tree_obj)
		{
			if ( tree_obj.state==false && tree_obj.reverse_state ) tree_obj.reverse_state();
			tree_obj = tree_obj.root;
		}
		
	}
	
};

const on_start_folder = (folder_name, root_page)=>{
	let res = {
		folders: [],
		pages: [],
		content_ref: root_page,
		container: document.createElement("div"),
		name: folder_name,
	};
	
	if (root_page)
	{
		root_page.tree_obj = res;
		document.getElementById("page-display-container-body").append(root_page);
	}
	
	if (!root_folder)
	{
		root_folder = res;
		document.getElementById("page-select-container").append(res.container);
		res.container.className = "ps-root-container";
	} else
	{
		currently_loading_folder.folders.push(res);
		res.root = currently_loading_folder;
		
		for (let t of broken_links)
			if (t.path.substr(0,t.path.indexOf('/')) == folder_name)
				t.path = t.path.substr(t.path.indexOf('/')+1); else
				t.path = "../"+t.path;
		
		res.body = document.createElement("div");
		res.body.className = "ps-folder";
		res.state = false;
		currently_loading_folder.container.append(res.body);
		
		res.update = ()=>{
			res.state_span.innerHTML = String.fromCharCode( res.empty? 0x2022 : res.state ? 0x25BC : 0x25BA );
			res.container.hidden = !res.state;
		}
		res.reverse_state = ()=>{
			res.state = !res.state;
			res.update();
		};
		
		res.state_span = document.createElement("span");
		res.body.append(res.state_span);
		
		res.name_span = document.createElement("span");
		res.name_span.className = "clickable-span";
		res.name_span.innerHTML = folder_name;
		if (root_page) root_page.name_span = res.name_span;
		res.body.append(res.name_span);
		if (root_page) res.name_span.addEventListener("click", ()=>select_page(root_page));
		
		res.container.className = "ps-container";
		res.body.append(res.container);
		
	}
	
	currently_loading_folder = res;
	if (root_page) fix_links(root_page);
}

const on_page_added = (page)=>{
	document.getElementById("page-display-container-body").append(page);
	fix_links(page);
	
	let res = {
		root: currently_loading_folder,
		name:  page.getAttribute("page_name"),
	};
	
	res.dot_span = document.createElement("span");
	res.dot_span.className = "dot-page-root";
	res.dot_span.innerHTML = String.fromCharCode( 0x2022 );
	currently_loading_folder.container.append(res.dot_span);
	
	res.name_span = document.createElement("span");
	res.name_span.innerHTML = res.name + "<br>";
	res.name_span.className = "ps-page";
	res.name_span.addEventListener("click", ()=>select_page(page));
	currently_loading_folder.container.append(res.name_span);
	page.name_span = res.name_span;
	
	res.content_ref = page;
	page.tree_obj = res;
	
	currently_loading_folder.pages.push(res);
	
	if (!selected_page) select_page(page);
}

const on_end_folder = ()=>{
	
	if (currently_loading_folder!=root_folder) {
		let folder = currently_loading_folder;
		
		if ( folder.folders.length || folder.pages.length )
		{
			folder.state_span.className = "clickable-span";
			folder.state_span.addEventListener("click", folder.reverse_state);
			folder.name_span.addEventListener("dblclick", folder.reverse_state);
		} else
		{
			folder.empty = true;
			folder.state_span.innerHTML = String.fromCharCode(0x2022);
			folder.state_span.className = "dot-page-root";
		}
		
		currently_loading_folder.update();
	}
	
	if (currently_loading_folder.name_span && !currently_loading_folder.content_ref)
	{
		let res = document.createElement("div");
		res.hidden = true;
		res.name_span = currently_loading_folder.name_span;
		res.name_span.addEventListener("click", ()=>select_page(res));
		document.getElementById("page-display-container-body").append(res);
		currently_loading_folder.content_ref = res;
		res.tree_obj = currently_loading_folder;
		
		if (currently_loading_folder.folders.length)
		{
			let h = document.createElement("h1");
			h.innerHTML = "Под-папки:";
			res.append(h);
			
			let l = document.createElement("ul");
			for (let folder of currently_loading_folder.folders)
			{
				let li = document.createElement("li");
				li.innerHTML = folder.name_span.innerHTML;
				make_smart_link(li, folder.content_ref);
				l.append(li);
			}
			res.append(l);
			
		}
		
		if (currently_loading_folder.pages.length)
		{
			let h = document.createElement("h1");
			h.innerHTML = "Страницы:";
			res.append(h);
			
			let l = document.createElement("ul");
			for (let page of currently_loading_folder.pages)
			{
				let li = document.createElement("li");
				li.innerHTML = page.name_span.innerHTML;
				make_smart_link(li, page.content_ref);
				l.append(li);
			}
			res.append(l);
			
		}
		
	}
	
	//try_fix_broken_links();
	
	broken_links = broken_links.map((t)=>{
		
		if (t.path.startsWith("../"))
		{
			t.path = t.path.substr(3);
			return t;
		} else
		{
			var page_name = t.path.toLowerCase();
			
			if (page_name == "")
				make_smart_link(t.lnk, currently_loading_folder.content_ref); else
				for (let page of currently_loading_folder.pages)
					if (page.name.toLowerCase() == page_name)
						make_smart_link(t.lnk, page.content_ref);
			
			return null;
		};
		
	}).filter((t)=>t);
	
	currently_loading_folder = currently_loading_folder.root;
}

/* ============================== *\
	       page display
\* ============================== */

const find_page_by_path = (path)=>{
	let folder = currently_loading_folder;
	
	while (path.startsWith("../"))
	{
		path = path.substr(3);
		folder = folder.root;
	}
	
	while (path.includes('/'))
	{
		let sfn = path.substr(0,path.indexOf('/')).toLowerCase();
		path = path.substr(path.indexOf('/')+1);
		
		let nfound = true;
		for (let sf of folder.folders)
			if (sf.name.toLowerCase() == sfn)
			{
				folder = sf;
				nfound = false;
				break;
			}
		
		if (nfound) return null;
	}
	
	if (path == "")
		return folder.content_ref; else
		for (let page of folder.pages)
			if (page.name.toLowerCase() == path.toLowerCase())
				return page.content_ref;
	
	return null;
}
const make_smart_link = (lnk, page)=>{
	lnk.className = "smart-link";
	lnk.addEventListener("click", ()=>select_page(page));
}

var broken_links = [];
const fix_links = (page)=>{
	
	for (let lnk of page.getElementsByTagName('a'))
	{
		lnk.path = lnk.getAttribute("path");
		lnk.removeAttribute("path");
		
		if (!lnk.path) continue;
		let page = find_page_by_path(lnk.path);
		if (page)
			make_smart_link(lnk, page); else
			broken_links.push({
				"path": lnk.path,
				"lnk": lnk
			});
		
	}
	
}

const code_words_color = {
	"pas": {
		"keyword": ["begin", "end", "var", "uses", "as", "new", "try", "except", "on", "do", "const"],
		"build-in": ["nil", "integer", "string"],
		"red": ["ToDo"],
	},
	"cl-c": {
		"keyword": ["__kernel"],
	},
	"default": {
		
	}
}

const fix_element = (page)=>{
	if (page.fixed) return;
	page.fixed = true;
	
	for (let spoiler of page.getElementsByClassName('spoiler'))
	{
		let get_spoiler_text = ()=> + ' ' + spoiler.getAttribute('summary');
		
		let wrap = document.createElement('p');
		wrap.className = "spoiler-wrap";
		wrap.update = ()=>{
			wrap.state_span.innerHTML = String.fromCharCode( 	spoiler.hidden ? 0x25BA : 0x25BC );
			wrap.style.border = 								spoiler.hidden ? "none" : null;
			wrap.style.marginLeft = 							spoiler.hidden ? "1px" 	: null;
		}
		
		wrap.state_span = document.createElement("span");
		wrap.update();
		wrap.append(wrap.state_span);
		
		wrap.name_span = document.createElement("span");
		wrap.name_span.innerHTML = spoiler.getAttribute("summary");
		wrap.append(wrap.name_span);
		
		wrap.reverse_state = ()=>{
			spoiler.hidden = !spoiler.hidden;
			wrap.update();
		}
		
		wrap.state_span.addEventListener("click", wrap.reverse_state);
		wrap.name_span.addEventListener("click", wrap.reverse_state);
		
		wrap.state_span.style.cursor = "pointer";
		wrap.name_span.style.cursor = "pointer";
		
		spoiler.replaceWith(wrap);
		wrap.append(spoiler);
	}
	
	for (let code of page.getElementsByTagName('code'))
	{
		let w_to_regex = (w)=>`(?<!\\w)${w}(?!\\w)`;
		
		// Автоопределение языка кода
		if (!code.className)
		{
			let best = {lang: null, c: 0};
			let multiple_best = true;
			
			for (let lang_name in code_words_color)
			{
				let c = 0;
				for (let wordt in code_words_color[lang_name])
					for (let w of code_words_color[lang_name][wordt])
					{
						var m = code.innerHTML.match(new RegExp( w_to_regex(w), "gi" ));
						if (m) c += m.length;
					}
				
				if (best.c == c)
					multiple_best = true; else
				if (best.c < c)
				{
					multiple_best = false;
					best.lang = lang_name;
					best.c = c;
				}
			}
			
			if (multiple_best)
				code.className = "language-default"; else
				code.className = "language-" + best.lang;
		}
		
		// Подсветка особых слов в коде
		{
			let lang = code.className.substr("language-".length);
			let curr_cw = code_words_color[lang];
			if (!curr_cw) curr_cw = code_words_color["default"];
			for (let wordt in curr_cw)
				code.innerHTML = code.innerHTML.replace(
					new RegExp(curr_cw[wordt].map(w_to_regex).join('|'),"gi"),
					w=> `<span class="code-${wordt}">${w}</span>`
				);
		}
		
		// Подсветка скобок
		{
			var br_types = {
				op: ["(", "[", "{", "&lt;", "'"],
				cl: [")", "]", "}", "&gt;", "'"],
			}
			for (let op in br_types)
				for (let i=0; i<br_types[op].length; i++)
					code.innerHTML = code.innerHTML.replace(
						new RegExp('\\'+br_types[op][i], "g"),
						`<span class=bracket ${ op=="op" ? "op=true" : "" } bt=${i}>${br_types[op][i]}</span>`
					);
			
			let br_st = [];
			for (let obj2 of code.getElementsByClassName("bracket"))
			{
				let b2t = obj2.getAttribute("bt");
				
				if (obj2.getAttribute("op"))
					br_st.push({
						obj: obj2,
						bt: b2t,
					}); else
				{
					let b1 = br_st.pop();
					let b0 = null;
					if (!b1) continue;
					if (b1.obj == obj2.parentElement)
					{
						b0 = b1;
						b1 = br_st.pop();
					}
					if (!b1) continue;
					if (b1.bt == b2t)
					{
						let obj1 = b1.obj;
						
						let on_enter = ()=>{
							obj1.className = "code-glowing-bracket";
							obj2.className = "code-glowing-bracket";
						}
						let on_leave = ()=>{
							obj1.className = null;
							obj2.className = null;
						}
						
						obj1.addEventListener("mouseenter", on_enter);
						obj2.addEventListener("mouseenter", on_enter);
						obj1.addEventListener("mouseleave", on_leave);
						obj2.addEventListener("mouseleave", on_leave);
					} else
					{
						br_st.push(b1);
						if (b0) br_st.push(b0);
					}
				}
				
			}
			
		}
		
		if (code.parentElement.tagName == "PRE")
		{
			let pre = code.parentElement;
			pre.className = 'code-block';
			
			let wrap = document.createElement('p');
			pre.replaceWith(wrap);
			wrap.append(pre);
			
		} else
			code.className = "inline-code";
		
	}
	
}


