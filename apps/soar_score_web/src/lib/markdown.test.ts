import { describe, expect, it } from "vitest";

import { renderMarkdown } from "./markdown";

describe("renderMarkdown", () => {
  it("renders headings, paragraphs and inline marks", () => {
    expect(renderMarkdown("# Title\n\nSome **bold** and *it* text\nsecond line.")).toBe(
      "<h1>Title</h1>\n<p>Some <strong>bold</strong> and <em>it</em> text second line.</p>",
    );
  });

  it("renders lists and tables", () => {
    const html = renderMarkdown("- a\n- b\n\n| X | Y |\n|---|---|\n| 1 | 2 |");
    expect(html).toContain("<ul><li>a</li><li>b</li></ul>");
    expect(html).toContain("<th>X</th>");
    expect(html).toContain("<td>2</td>");
  });

  it("escapes HTML and only links http or site paths", () => {
    const html = renderMarkdown('<script>x</script> [ok](https://a.b) [bad](javascript:alert(1))');
    expect(html).not.toContain("<script>");
    expect(html).toContain('<a href="https://a.b">ok</a>');
    expect(html).not.toContain('href="javascript');
  });
});
