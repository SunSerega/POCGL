


/* ============================== *\
		        misc
\* ============================== */

const selected_name_color = "#eaeaea";
const  pointed_name_color = "#d1faff";

/* ============================== *\
		     page load
\* ============================== */

var root_folder = null;
var currently_loading_folder = null;

var page_by_path = {};
const define_page_with_path = (path, page)=>{
	
	if (page_by_path[path])
		console.error(`page with path "${path}" defined multiple times`); else
		page_by_path[path] = page;
	
	if (broken_links[path])
	{
		for (let lnk of broken_links[path])
			lnk.fix(page);
		delete broken_links[path];
	}
	
}

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
		if (root_page) select_page(root_page);
		root_folder = res;
		res.path = "";
		document.getElementById("page-select-container").append(res.container);
		res.container.className = "ps-root-container";
	} else
	{
		currently_loading_folder.folders.push(res);
		res.root = currently_loading_folder;
		res.path = res.root.path + folder_name + '/';
		
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
		res.name_span.className = "ps-folder-name";
		res.name_span.innerHTML = folder_name;
		if (root_page) root_page.name_span = res.name_span;
		res.body.append(res.name_span);
		//
		if (root_page) res.name_span.addEventListener("click", ()=>select_page(root_page));
		res.name_span.addEventListener("mouseenter", ()=>{ if (is_selected(res.name_span)) res.name_span.style.backgroundColor=pointed_name_color; });
		res.name_span.addEventListener("mouseleave", ()=>{ if (is_selected(res.name_span)) res.name_span.style.backgroundColor="inherit"; });
		
		res.container.className = "ps-container";
		res.body.append(res.container);
		
	}
	
	currently_loading_folder = res;
	if (root_page) fix_links(root_page);
}

const on_page_added = (page)=>{
	document.getElementById("page-display-container-body").append(page);
	
	let res = {
		root: currently_loading_folder,
		name: page.getAttribute("page_name"),
	};
	res.path = currently_loading_folder.path + res.name;
	
	res.cont_div = document.createElement("div");
	res.cont_div.className = "ps-page";
	currently_loading_folder.container.append(res.cont_div);
	
	res.dot_span = document.createElement("span");
	res.dot_span.className = "dot-page-root";
	res.dot_span.innerHTML = String.fromCharCode( 0x2022 );
	res.cont_div.append(res.dot_span);
	
	res.name_span = document.createElement("span");
	res.name_span.innerHTML = res.name + "<br>";
	res.name_span.className = "ps-page-name";
	res.name_span.addEventListener("click", ()=>select_page(page));
	res.name_span.addEventListener("mouseenter", ()=>{ if (is_selected(res.name_span)) res.name_span.style.backgroundColor=pointed_name_color; });
	res.name_span.addEventListener("mouseleave", ()=>{ if (is_selected(res.name_span)) res.name_span.style.backgroundColor="inherit"; });
	res.cont_div.append(res.name_span);
	page.name_span = res.name_span;
	
	res.content_ref = page;
	page.tree_obj = res;
	
	currently_loading_folder.pages.push(res);
	define_page_with_path(res.path, page);
	fix_links(page);
	
	if (!selected_page && !document.location.hash) select_page(page);
}

const on_end_folder = ()=>{
	
	if (currently_loading_folder!=root_folder) {
		let folder = currently_loading_folder;
		
		if ( folder.folders.length || folder.pages.length )
		{
			folder.state_span.className = "arrow-page-root";
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
	
	if (currently_loading_folder !== root_folder)
	{
		
		if (!currently_loading_folder.content_ref)
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
		
		define_page_with_path(currently_loading_folder.path, currently_loading_folder.content_ref);
		currently_loading_folder = currently_loading_folder.root;
	}
	
}

/* ============================== *\
	        page display
\* ============================== */

var selected_page = null;
const is_selected = (name_span)=>(!selected_page || selected_page.name_span!==name_span);
const select_page = (new_page)=>{
	if (selected_page == new_page) return;
	document.location.hash = new_page.tree_obj.path;
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
		if (name_span) name_span.style.backgroundColor = selected_name_color;
		
		let tree_obj = new_page.tree_obj.root;
		while (tree_obj)
		{
			if ( tree_obj.state==false && tree_obj.reverse_state ) tree_obj.reverse_state();
			tree_obj = tree_obj.root;
		}
		
	}
	
}

const make_smart_link = (lnk, page)=>{
	lnk.className = "smart-link";
	lnk.addEventListener("click", ()=>select_page(page));
}

var broken_links = {};
const define_broken_lnk = (path, source, fixer)=>{
	if (!broken_links[path]) broken_links[path] = [];
	broken_links[path].push({
		source:	source,
		fix:	fixer,
	});
}

const fix_links = (page)=>{
	
	for (let lnk of page.getElementsByTagName('a'))
	{
		lnk.path = lnk.getAttribute("path");
		if (!lnk.path) continue;
		lnk.removeAttribute("path");
		
		start_folder = currently_loading_folder;
		while (lnk.path.startsWith("../"))
		{
			start_folder = start_folder.root;
			lnk.path = lnk.path.substr(3);
		}
		lnk.path = start_folder.path+lnk.path;
		
		let lnk_page = page_by_path[lnk.path];
		if (lnk_page)
			make_smart_link(lnk, lnk_page); else
			define_broken_lnk(lnk.path, page.tree_obj.path, new_page=>make_smart_link(lnk, new_page))
		
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

/* ============================== *\
		        init
\* ============================== */

{
	if (document.location.hash)
		define_broken_lnk(
			decodeURIComponent(document.location.hash.substr(1)),
			"document.location.hash",
			page=>select_page(page)
		);
	
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

window.onload = ()=>{
	
	for (path in broken_links)
		console.error(`Page "${path}" referenced ${broken_links[path].length} times but not found:`, broken_links[path].map(lnk=>lnk.source));
	
}


