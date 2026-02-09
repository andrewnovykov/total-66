defmodule HeadsUpWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HeadsUpWeb, :html

  embed_templates "page_html/*"

  def get_default_goal_image do
    "https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=400&h=300&fit=crop"
  end

  def get_default_group_image do
    "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&h=400&fit=crop"
  end

  def get_default_user_image do
    "https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400&h=400&fit=crop"
  end
end
