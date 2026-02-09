defmodule HeadsUpWeb.Components.CommitmentChart do
  use Phoenix.Component

  def commitment_chart(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
      <!-- Header -->
      <div class="px-6 py-4 border-b border-gray-100 bg-gray-50">
        <div class="flex justify-between items-center">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Activity Chart</h3>
            <p class="text-sm text-gray-600 mt-1">Your commitment over the past year</p>
          </div>
          <div class="text-right">
            <div class="text-sm font-medium text-gray-700">{length(@chart_data)}</div>
            <div class="text-xs text-gray-500">days tracked</div>
          </div>
        </div>
      </div>
      
    <!-- Chart Content -->
      <div class="p-6">
        <!-- Month Labels -->
        <div class="flex justify-between text-xs text-gray-500 mb-2 px-3">
          <span>Jan</span>
          <span>Feb</span>
          <span>Mar</span>
          <span>Apr</span>
          <span>May</span>
          <span>Jun</span>
          <span>Jul</span>
          <span>Aug</span>
          <span>Sep</span>
          <span>Oct</span>
          <span>Nov</span>
          <span>Dec</span>
        </div>
        
    <!-- Chart Grid Container -->
        <div class="bg-gray-50 rounded-lg p-3 mb-4 overflow-x-auto">
          <!-- The chart grid -->
          <div class="flex">
            <!-- Day labels column -->
            <div
              class="flex flex-col justify-between text-xs text-gray-500 pr-3"
              style="height: 90px;"
            >
              <span>Mon</span>
              <span></span>
              <span>Wed</span>
              <span></span>
              <span>Fri</span>
              <span></span>
              <span>Sun</span>
            </div>
            
    <!-- Chart grid: 7 rows × 53 columns -->
            <div
              class="grid gap-[2px]"
              style="grid-template-rows: repeat(7, 12px); grid-template-columns: repeat(53, 12px); grid-auto-flow: column;"
            >
              <%= for day_data <- organize_chart_data(@chart_data) do %>
                <div
                  class={"w-3 h-3 rounded-sm transition-all duration-200 hover:scale-110 cursor-pointer #{intensity_color(day_data.intensity)}"}
                  title={"#{day_data.date}: #{day_data.activity_count} activities, #{day_data.xp_total} XP"}
                >
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Legend -->
        <div class="flex items-center justify-between text-xs mb-6">
          <span class="text-gray-500">Less active</span>
          <div class="flex items-center space-x-1">
            <div class="w-3 h-3 bg-gray-200 rounded-sm border"></div>
            <div class="w-3 h-3 bg-blue-200 rounded-sm"></div>
            <div class="w-3 h-3 bg-blue-400 rounded-sm"></div>
            <div class="w-3 h-3 bg-blue-600 rounded-sm"></div>
            <div class="w-3 h-3 bg-blue-800 rounded-sm"></div>
          </div>
          <span class="text-gray-500">More active</span>
        </div>
        
    <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-4 text-center border border-blue-200">
            <div class="text-2xl font-bold text-blue-700">{@activity_summary.total_xp}</div>
            <div class="text-sm text-blue-600 font-medium">Total XP</div>
            <div class="text-xs text-blue-500 mt-1">Experience Points</div>
          </div>

          <div class="bg-gradient-to-r from-indigo-50 to-indigo-100 rounded-lg p-4 text-center border border-indigo-200">
            <div class="text-2xl font-bold text-indigo-700">{@user_level}</div>
            <div class="text-sm text-indigo-600 font-medium">Current Level</div>
            <div class="text-xs text-indigo-500 mt-1">Achievement Rank</div>
          </div>

          <div class="bg-gradient-to-r from-sky-50 to-sky-100 rounded-lg p-4 text-center border border-sky-200">
            <div class="text-2xl font-bold text-sky-700">{get_streak(@chart_data)}</div>
            <div class="text-sm text-sky-600 font-medium">Current Streak</div>
            <div class="text-xs text-sky-500 mt-1">Consecutive Days</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp intensity_color(0), do: "bg-gray-100"
  defp intensity_color(1), do: "bg-blue-200"
  defp intensity_color(2), do: "bg-blue-400"
  defp intensity_color(3), do: "bg-blue-600"
  defp intensity_color(4), do: "bg-blue-800"
  defp intensity_color(_), do: "bg-blue-800"

  defp organize_chart_data(chart_data) do
    # Start from Sunday of the first week containing the first date
    first_date = List.first(chart_data) |> Map.get(:date, Date.utc_today())

    # Calculate the Sunday before or on the first date
    days_from_sunday = Date.day_of_week(first_date, :sunday) - 1
    start_date = Date.add(first_date, -days_from_sunday)

    # Create a map of existing data for quick lookup
    data_map = Map.new(chart_data, fn day -> {day.date, day} end)

    # Generate 53 weeks × 7 days = 371 days to ensure full year coverage
    for week <- 0..52, day_of_week <- 0..6 do
      date = Date.add(start_date, week * 7 + day_of_week)

      case Map.get(data_map, date) do
        nil ->
          %{
            date: date,
            activity_count: 0,
            xp_total: 0,
            intensity: 0
          }

        existing_data ->
          existing_data
      end
    end
  end

  defp get_streak(chart_data) do
    chart_data
    |> Enum.reverse()
    |> Enum.reduce_while(0, fn day, acc ->
      if day.activity_count > 0 do
        {:cont, acc + 1}
      else
        {:halt, acc}
      end
    end)
  end
end
