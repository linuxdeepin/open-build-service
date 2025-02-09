class WatchlistComponent < ApplicationComponent
  WATCHABLE_TYPE_TEXT = {
    'Package' => 'package',
    'Project' => 'project',
    'BsRequest' => 'request'
  }.freeze

  def initialize(user:, current_object:, bs_request: nil, package: nil, project: nil)
    super

    @user = user
    @object_to_be_watched = object_to_be_watched(bs_request, package, project)
    @current_object = current_object
  end

  private

  def object_to_be_watched(bs_request, package, project)
    return bs_request if bs_request

    # this is a remote project, don't offer watching.
    return unless project.is_a?(Project)

    # there is no package, offer watching the project
    return project unless package

    # maybe package is a multibuild flavor? Try do look up the object of the flavor.
    package = Package.get_by_project_and_name(project, package, { follow_multibuild: true }) if package.is_a?(String)

    # the package is coming via a project link, don't offer watching it.
    return if package.project != project

    package
  end

  def object_to_be_watched_in_watchlist?
    @user.watched_items.exists?(watchable: @current_object)
  end

  def watchable_type_text
    WATCHABLE_TYPE_TEXT[@current_object.class.name]
  end

  def toggle_watchable_path
    case @current_object
    when Package
      project_package_toggle_watched_item_path(project_name: @current_object.project.name, package_name: @current_object.name)
    when Project
      project_toggle_watched_item_path(project_name: @current_object.name)
    when BsRequest
      toggle_watched_item_request_path(number: @current_object.number)
    end
  end

  def projects
    @projects ||= ProjectsForWatchlistFinder.new.call(@user)
  end

  def packages
    @packages ||= PackagesForWatchlistFinder.new.call(@user)
  end

  def bs_requests
    @bs_requests ||= RequestsForWatchlistFinder.new.call(@user)
  end
end
