defmodule HeadsUpWeb.Components.UI.ThreeColumnLayout do
  use Phoenix.Component

  slot :left_sidebar
  slot :main_content, required: true
  slot :right_sidebar

  def three_column_layout(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 pb-24 lg:pb-6">
      <div class="lg:grid lg:grid-cols-12 lg:gap-8">
        <%!-- Left Sidebar --%>
        <aside :if={@left_sidebar != []} class="hidden lg:block lg:col-span-3">
          <div class="sticky top-24 space-y-6">
            {render_slot(@left_sidebar)}
          </div>
        </aside>

        <%!-- Main Content --%>
        <main class={[
          "space-y-6",
          @left_sidebar != [] && @right_sidebar != [] && "lg:col-span-6",
          @left_sidebar != [] && @right_sidebar == [] && "lg:col-span-9",
          @left_sidebar == [] && @right_sidebar != [] && "lg:col-span-9",
          @left_sidebar == [] && @right_sidebar == [] && "lg:col-span-12"
        ]}>
          {render_slot(@main_content)}
        </main>

        <%!-- Right Sidebar --%>
        <aside :if={@right_sidebar != []} class="hidden lg:block lg:col-span-3">
          <div class="sticky top-24 space-y-6">
            {render_slot(@right_sidebar)}
          </div>
        </aside>
      </div>
    </div>
    """
  end
end
