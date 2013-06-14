# -*- coding: utf-8 -*-
# Copyright 2008-2010 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of VCC (Virtual Conference Center).
#
# VCC is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VCC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with VCC.  If not, see <http://www.gnu.org/licenses/>.

# Require Station Controller
require_dependency "#{ Rails.root.to_s }/vendor/plugins/station/app/controllers/join_requests_controller"

class JoinRequestsController
  before_filter :space!

  def new
    if space.users.include?(current_agent)
      flash[:notice] = t('join_request.joined')
      redirect_to space
      return
    end
    respond_to do |format|
      format.html{
        if request.xhr?
          render :layout => false
        end
      }
    end
  end

  def create
    if space.users.include?(current_agent)
      flash[:notice] = t('join_request.joined')
      if request.xhr?
        render :partial=> "redirect.js.erb", :locals => {:url => space_path(space)}
      else
        redirect_to space
      end
      return
    end

    @join_request = space.join_requests.new(params[:join_request])
    @join_request.candidate = current_user

    if @join_request.save
      flash[:notice] = t('join_request.created')
    else

      flash[:error] = t('join_request.already_sent')
      # TODO: identify errors for better usability
      # flash[:error] << @join_request.errors.to_xml
    end

    if request.xhr?
      if space.public
        render :partial => "redirect.js.erb", :locals => {:url => space_path(space)}
      else
        render :partial => "redirect.js.erb", :locals => {:url => spaces_path}
      end
    else
      if space.public
        redirect_to space_path(space)
      else
        redirect_to spaces_path
      end
    end
  end

end
