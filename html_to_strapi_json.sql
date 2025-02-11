CREATE OR REPLACE FUNCTION html_to_strapi_json(html_content text)
RETURNS jsonb
LANGUAGE plpython3u
AS $$
from bs4 import BeautifulSoup
import json

def parse_node(node):
    # Handle text nodes
    if node.name is None:
        return {"type": "text", "text": str(node)}
    
    # Normalize tag name
    tag = node.name.lower()
    node_data = {}
    
    # --- Block elements ---
    if tag == "p":
        node_data["type"] = "paragraph"
    elif tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
        node_data["type"] = "heading"
        node_data["level"] = int(tag[1])
    elif tag in ("ul", "ol"):
        node_data["type"] = "list"
        node_data["format"] = "unordered" if tag == "ul" else "ordered"
    elif tag == "li":
        node_data["type"] = "list-item"
    elif tag == "blockquote":
        node_data["type"] = "quote"
    elif tag == "hr":
        node_data["type"] = "horizontal-rule"
        return node_data
    elif tag == "img":
        node_data["type"] = "image"
        if node.has_attr("src"):
            node_data["url"] = node["src"]
        if node.has_attr("alt"):
            node_data["alt"] = node["alt"]
        if node.has_attr("width"):
            node_data["width"] = node["width"]
        if node.has_attr("height"):
            node_data["height"] = node["height"]
        return node_data

    # --- Inline elements ---
    elif tag == "a" and node.has_attr("href"):
        node_data["type"] = "link"
        node_data["url"] = node["href"]
    elif tag in ("strong", "b"):
        node_data["type"] = "text"
        node_data["bold"] = True
    elif tag in ("em", "i"):
        node_data["type"] = "text"
        node_data["italic"] = True
    elif tag == "u":
        node_data["type"] = "text"
        node_data["underline"] = True
    elif tag in ("s", "strike"):
        node_data["type"] = "text"
        node_data["strikethrough"] = True
    elif tag == "code":
        node_data["type"] = "text"
        node_data["code"] = True
    elif tag == "sub":
        node_data["type"] = "text"
        node_data["subscript"] = True
    elif tag == "sup":
        node_data["type"] = "text"
        node_data["superscript"] = True
    elif tag == "br":
        # Represent a <br> as a newline within a text node
        return {"type": "text", "text": "\n"}
    else:
        # For unknown tags (eg div, span), treat them as a fragment
        node_data["type"] = "fragment"

    # Process children recursively
    children = []
    for child in node.children:
        parsed_child = parse_node(child)
        if parsed_child:
            if isinstance(parsed_child, list):
                children.extend(parsed_child)
            else:
                children.append(parsed_child)

    # For inline formatting (eg strong, em etc), combine any text children
    if tag in ("strong", "b", "em", "i", "u", "s", "strike", "code", "sub", "sup"):
        combined_text = "".join(child.get("text", "") for child in children if child.get("type") == "text")
        node_data["text"] = combined_text
        return node_data

    # Attach children if present
    if children:
        # For nodes that should have inline children, assign them directly
        if node_data["type"] in ("paragraph", "heading", "list-item", "quote", "link", "fragment", "list"):
            node_data["children"] = children
        else:
            node_data["children"] = children
    else:
        # Ensure block nodes always have a children array (even if empty)
        if node_data["type"] in ("paragraph", "heading", "list-item", "quote", "link", "fragment", "list"):
            node_data["children"] = [{"type": "text", "text": ""}]

    # If a fragment, just return its children to avoid extra nesting
    if node_data.get("type") == "fragment":
        return children

    return node_data

# If html_content is empty, return an empty paragraph block.
if html_content is None or not html_content.strip():
    return json.dumps([{"type": "paragraph", "children": [{"type": "text", "text": ""}]}])

soup = BeautifulSoup(html_content, 'html.parser')
result = []

# Process top-level nodes. If an inline element is at top-level, wrap it in a paragraph.
for element in soup.contents:
    parsed = parse_node(element)
    if isinstance(parsed, list):
        for node in parsed:
            if node.get("type") == "text":
                result.append({"type": "paragraph", "children": [node]})
            else:
                result.append(node)
    else:
        if parsed.get("type") == "text":
            result.append({"type": "paragraph", "children": [parsed]})
        else:
            result.append(parsed)

return json.dumps(result)
$$;
