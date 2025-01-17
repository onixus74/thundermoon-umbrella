defmodule ThundermoonWeb.LotkaVolterraLive.EditButton do
  use ThundermoonWeb, :live_component

  def render(assigns) do
    ~H"""
    <div x-data="{ showForm: false }" x-cloak x-transition class="inline relative">
      <a @click.prevent="showForm = !showForm" class="btn btn-outline">
        <i class="las la-plus-circle"></i>
        <%= @button_label %>
      </a>
      <div x-show="showForm" class="absolute left-0 bottom-7">
        <div class="border bg-gray-800 border-gray-600 rounded-md p-4">
          <%= render_block(@inner_block) %>
        </div>
        <i class="las la-angle-down"></i>
      </div>
    </div>
    """
  end
end
