module CommentsHelper
  def format_body(text)
    h(text).gsub(/\n(\s*\n)+/, "\n<p>")
  end
end
