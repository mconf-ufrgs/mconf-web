require "spec_helper"

describe SpacesController do

  include ActionController::AuthenticationTestHelper

  render_views

  before(:each) do
    # the superuser
    @superuser = Factory(:superuser)

    # private spaces
    @private_space = Factory(:private_space)
    @user = Factory(:user_performance, :stage => @private_space).agent
    @invited = Factory(:invited_performance, :stage => @private_space).agent

    @private_space2 = Factory(:private_space)
    @admin = Factory(:admin_performance, :stage => @private_space2).agent

    # a public space
    @public_space = Factory(:public_space)
  end

  describe "A Superadmin" do
    before(:each) do
      login_as(@superuser)
    end
    it "should be able to create a new space" do
      valid_attributes = Factory.attributes_for(:public_space)
      post :create, :space => valid_attributes
      assert_response 302
      space = Space.find_by_name(valid_attributes[:name])
      response.should redirect_to(space_path(space))
    end
    it "should be able to see public spaces " do
      get :show, :id => @public_space.to_param
      assert_response 200
      response.should render_template("spaces/show")
    end
    it "should be able to delete a public space" do
      delete :destroy , :id => @public_space.to_param
      assert_response 302
      response.should redirect_to(spaces_url)
    end
    it "should be able to see  private spaces" do
      get :show, :id => @private_space.to_param, :user_id => @superuser.id
      assert_response 200
      response.should render_template("spaces/show")
    end
    it "should be able to delete a private  space" do
      delete :destroy , :id => @private_space.to_param, :user_id => @superuser.id
      assert_response 302
      response.should redirect_to(spaces_url)
    end
  end

  describe "The admin of a space" do
    before(:each) do
      login_as(@admin)
    end
    it "should be able to delete his own space" do
      delete :destroy , :id => @private_space2.to_param, :user_id => @admin.id
      assert_response 302
      response.should redirect_to(spaces_url)
    end

    it "should NOT be able to delete other spaces if he isn't the admin" do
      delete :destroy, :id => @private_space.to_param, :user_id => @user.id
      assert_response 403

    end

  end


  describe "A logged user" do
    before(:each) do
      login_as(@user)
    end

    it "should be able to create a new space" do
      valid_attributes = Factory.attributes_for(:public_space)
      post :create, :space=> valid_attributes
      assert_response 302
      space = Space.find_by_name(valid_attributes[:name])
      response.should redirect_to(space_path(space))
    end

    it "should be able to see public spaces" do
      get :show, :id => @public_space.to_param
      assert_response 200
      response.should render_template("spaces/show")
    end
    it "should be able to see private spaces if he is joined to them" do
      get :show, :id => @private_space.to_param, :user_id => @user.id
      assert_response 200
      response.should render_template("spaces/show")
    end
    it "should NOT be able to see private spaces if he isn't joined to them" do
      get :show, :id => @private_space2.to_param, :user_id => @user.id
      assert_response 302
      response.should redirect_to(new_space_join_request_url(@private_space2))
    end
    it "should NOT be able to delete anyone's space " do
      delete :destroy, :id => @private_space.to_param, :user_id => @user.id
      assert_response 403
    end
  end

  describe "An invited user" do
    before(:each) do
      login_as(@invited)
    end

    it "should be able to see public spaces" do
      get :show, :id => @public_space.to_param
      assert_response 200
      response.should render_template("spaces/show")
    end

    it "should be able to see spaces where he's invited" do
      get :show, :id => @private_space.to_param
      assert_response 200
      response.should render_template("spaces/show")
    end

    it "should not be able to see spaces where he's not invited" do
      get :show, :id => @private_space2.to_param
      assert_response 302
      response.should redirect_to(new_space_join_request_url(@private_space2))
    end

    it "should NOT be able to delete anyone's space " do
      delete :destroy, :id => @private_space.to_param, :user_id => @invited.id
      assert_response 403
    end

    it "should  NOT be able to create a new space" do
      valid_attributes = Factory.attributes_for(:public_space)
      post :create, :space=> valid_attributes
      assert_response 302
    end

    pending "should NOT be able to open the conference room"

  end

  describe " A NOT logged user" do
    it "should be able to see public spaces" do
      get :show, :id => @public_space.to_param
      assert_response 200
      response.should render_template("spaces/show")
    end

    it "should NOT be able to see private spaces" do
      private_space3= Factory(:private_space)
      get :show, :id => private_space3.to_param, :format => :html
      assert_response 302
      response.should redirect_to(new_session_path)
    end

    it "should NOT be able to delete a space" do
      delete :destroy, :id => @public_space.to_param
      assert_response 302
      response.should redirect_to(new_session_path)
    end
  end

  describe "a space#bigbluebutton_room is" do
    before(:each) do
      login_as(@superuser)
    end

    it "created when the space is created" do
      expect {
        post :create, :space => Factory.attributes_for(:public_space)
      }.to change{ BigbluebuttonRoom.count }.by(1)
      space = Space.last
      room = space.bigbluebutton_room

      room.should_not be_nil
      room.name.should == space.permalink
      room.owner_id.should == space.id
      room.owner_type.should == space.class.name
    end

    # ps: the room is destroyed when the space (the model) is destroyed

  end

=begin
  include ActionController::AuthenticationTestHelper
  fixtures :users , :spaces , :performances, :roles, :permissions



  def mock_space(stubs={})
    @mock_space ||= mock_model(space, stubs)
  end


  describe "responding to GET index" do

    describe "when you are logged in" do

      describe "as super Admin" do

        before(:each) do
          login_as(:user_admin)
        end

        it "should let users to see the space index" do
          get :index
          assigns[:spaces].should_not equal(nil)
          assert_response 200
        end
      end

      describe "as normal User" do

        before(:each) do
          login_as(:user_normal)
        end

        it "should let users to see the space index" do
          get :index
          assigns[:spaces].should_not equal(nil)
          assert_response 200
        end
      end
    end

    describe "when you are not logged in" do

      it "should let users to see the space index" do
        get :index
        assigns[:spaces].should_not equal(nil)
        assert_response 200
      end
    end
  end

#####################


  describe "responding to GET show" do

    describe " When you are logged in" do

      describe "as Super Admin" do

        before(:each) do
          login_as(:user_admin)
        end

        it "should let Super Admin to see a private space" do
          get :show, :id => spaces(:private_no_roles).name
          assert_response 200
        end

        it "should let Super Admin to see the public space" do
          get :show, :id => spaces(:public).name
          assert_response 200
        end
      end

      describe "as normal User" do

        before(:each)do
          login_as(:user_normal)
        end

        describe " in a private space where the user has the role Admin" do
          it "should let the user to see a private space" do
            get :show, :id => spaces(:private_admin).name
            assert_response 200
          end
        end

        describe " in a private space where the user has the role User" do
          it "should let the user to see a private space" do
            get :show, :id => spaces(:private_user).name
            assert_response 200
          end
        end

        describe "in a private space where the user has the role Invited" do
          it "should let the user to see a private space" do
            get :show, :id => spaces(:private_invited).name
            assert_response 200
          end
        end

        describe "in a private space where the user has no roles" do
          it "should not let the user to see a private space" do
            get :show, :id => spaces(:private_no_roles).name
            assert_response 403
          end
        end

        describe "in the public space" do
          it "should let the user to see a private space" do
            get :show, :id => spaces(:public).name
            assert_response 200
          end
        end
      end
    end

    describe "If you are not logged in" do
      it "should not let the user to see a private space" do
        get :show, :id => spaces(:private_no_roles).name
        assert_response 403
      end

      it "should let the user to see a public space" do
        get :show, :id => spaces(:public).name
        assert_response 200
      end
    end
  end

##########################

  describe "responding to GET new" do

    describe "when you are logged in" do
      describe " as Super Admin" do

        before(:each) do
          login_as(:user_admin)
        end

        it "should let the User to create a space and the user" do
          get :new
          assert_response 200
        end
      end

      describe " as normal User" do

        before(:each)do
          login_as(:user_normal)
        end

        it "should let the User to create a space and this User should be admin of this space" do
          get :new
          assert_response 200
        end
      end
    end

    describe "if you are not logged in" do

      it "should not let to create a space" do
        get :new
        assert_response 401
      end
    end
  end


##########################
  describe "responding to GET edit" do

    describe"when you are logged in" do
      describe "as Super Admin" do

        before(:each) do
          login_as(:user_admin)
        end

        it "should let the user to edit a private space" do
          get :edit , :id => spaces(:private_no_roles).name
          assert_response 200
        end

        it "should let the user to edit a public space" do
          get :edit , :id => spaces(:public).name
          assert_response 200
        end
      end

      describe "as normal User" do

        before(:each) do
          login_as(:user_normal)
        end

        it "should let the user to edit a private space where the user has the Admin role" do
          get :edit , :id => spaces(:private_admin).name
          assert_response 200
        end

        it "should NOT let the user to edit a private space where the user has the USER role" do
          get :edit , :id => spaces(:private_user).name
          assert_response 403
        end

        it "should NOT let the user to edit a private space where the user has the INVITED role" do
          get :edit , :id => spaces(:private_invited).name
          assert_response 403
        end

        it "should NOT let the user to edit a private space where the user has no roles" do
          get :edit , :id => spaces(:private_no_roles).name
          assert_response 403
        end

        it "should NOT let the user to edit a public space where the user has no roles" do
          get :edit , :id => spaces(:public).name
          assert_response 403
        end
      end
    end

    describe "if you are not logged in" do

      it "should ask the user for authentication to edit a private space" do
        get :edit , :id => spaces(:private_no_roles).name
        assert_response 401
      end

      it "should NOT let the user to edit a public space" do
        get :edit , :id => spaces(:public).name
        assert_response 401
      end
    end

#it "should expose the requested space as @space" do
#Space.should_receive(:find).with("37").and_return(mock_space)
#get :edit, :id => "37"
#assigns[:space].should equal(mock_space)
#end

  end

#################

  describe "responding to POST create" do

    describe "with valid params" do

      before(:each)do
        @valid_attributes = {:name => 'title', :description => 'text'
        }
      end

      describe " When you are logged in " do

        describe "as Super Admin" do

          before(:each) do
            login_as(:user_admin)
          end

          it "should let the User to create a space and the user and redirect to the index space" do
            assert_difference 'Space.count', +1 do
              get :create ,:space => @valid_attributes
            end
            response.should redirect_to(spaces_path)
          end
        end

        describe "as Normal User" do

          before(:each) do
            login_as(:user_normal)
          end

          it "should let the User to create a space and the user and redirect to the index space" do
            assert_difference 'Space.count', +1 do
              get :create ,:space => @valid_attributes
            end
            response.should redirect_to(spaces_path)
          end
        end
      end

      describe "if you are not logged in" do

        it "should NOT let the User to create a space " do
          assert_no_difference 'Space.count' do
            get :create ,:space => @valid_attributes
          end
          assert_response 401
        end
      end

#it "should expose a newly created space as @space" do
#  Space.should_receive(:new).with({'these' => 'params'}).and_return(mock_space(:save => true))
#  post :create, :space => {:these => 'params'}
#  assigns(:space).should equal(mock_space)
#end

#it "should redirect to the created space" do
#  Space.stub!(:new).and_return(mock_space(:save => true))
#  post :create, :space => {}
#  response.should redirect_to(spaces_url)
#end

    end

    describe "with invalid params" do

      before(:each)do
        @invalid_attributes = { }
      end

      describe " When you are logged in " do

        describe "as Super Admin" do

          before(:each) do
            login_as(:user_admin)
          end

          it "should let the User to try to create a space but with invalid params the space should not be created" do
            assert_no_difference 'Space.count', +1 do
              post :create ,:space => @invalid_attributes
            end
            response.should render_template('new')
          end
        end

        describe "as Normal User" do

          before(:each) do
            login_as(:user_normal)
          end

          it "should let the User to try to create a space but with invalid params the space should not be created" do
            assert_no_difference 'Space.count', +1 do
              post :create ,:space => @invalid_attributes, :format => 'html'
            end
            response.should render_template("spaces/new")
          end
        end
      end

      describe "if you are not logged in" do

        it "should NOT let the User to try to create a space " do
          assert_no_difference 'Space.count' do
            post :create ,:space => @invalid_attributes, :format => 'html'
          end
          assert_redirected_to new_session_path
        end
      end



#it "should expose a newly created but unsaved space as @space" do
#  Space.stub!(:new).with({'these' => 'params'}).and_return(mock_space(:save => false))
#  post :create, :space => {:these => 'params'}
#  assigns(:space).should equal(mock_space)
#end

#it "should re-render the 'new' template" do
#  Space.stub!(:new).and_return(mock_space(:save => false))
#  post :create, :space => {}
#  response.should render_template('index')
#end

    end
  end


####################

  describe "responding to PUT udpate" do

    describe "with valid params" do

      before(:each)do
        @valid_attributes = {:name => 'title', :description => 'text'
        }
      end

      describe " when you are logged in" do

        describe " as super Admin" do

          before(:each)do
            login_as(:user_admin)
          end

          it "should let the User to edit a private space and redirect to the index space" do
            get :update ,:space => @valid_attributes , :id => spaces(:private_no_roles).name
            response.should redirect_to(space_path(assigns[:space]))
          end

          it "should let the User to edit a public space and redirect to the index space" do
            get :update ,:space => @valid_attributes , :id => spaces(:public).name
            response.should redirect_to(space_path(assigns[:space]))
          end
        end

        describe " as normal user" do

          before(:each)do
            login_as(:user_normal)
          end

          it "should let the User to edit a private space where the user has the role admin and redirect to the index space" do
            get :update ,:space => @valid_attributes , :id => spaces(:private_admin).name
            response.should redirect_to(space_path(assigns[:space]))
          end

          it "should NOT let the User to edit a private space where the user has the role User" do
            get :update ,:space => @valid_attributes , :id => spaces(:private_user).name
            assert_response 403
          end

          it "should NOT let the User to edit a private space where the user has the role invited " do
            get :update ,:space => @valid_attributes , :id => spaces(:private_invited).name
            assert_response 403
          end

          it "should NOT let the User to edit a private space where the user has NO roles" do
            get :update ,:space => @valid_attributes , :id => spaces(:private_no_roles).name
            assert_response 403
          end

          it "should NOT let the User to edit a public space where the user has no roles" do
            get :update ,:space => @valid_attributes , :id => spaces(:public).name
            assert_response 403
          end
        end
      end

      describe "if you are not logged in" do

        it "should NOT let the User to edit a private space " do
          get :update ,:space => @valid_attributes , :id => spaces(:private_no_roles).name
          assert_response 401
        end

        it "should NOT let the User to edit a public space " do
          get :update ,:space => @valid_attributes , :id => spaces(:public).name
          assert_response 401
        end
      end
    end

    describe "with invalid params" do

      before(:each)do
        @invalid_attributes = {}
      end

      describe " when you are logged in" do

        describe " as super Admin" do

          before(:each)do
            login_as(:user_admin)
          end

          it "should NOT let the User to edit a private space and redirect to the space" do
            get :update ,:space => @invalid_attributes , :id => spaces(:private_no_roles).name
            response.should redirect_to(space_path(spaces(:private_no_roles).name))
          end

          it "should NOt let the User to edit a public space and render the edit action" do
            get :update ,:space => @invalid_attributes , :id => spaces(:public).name
            response.should redirect_to(space_path(spaces(:public).name))
          end
        end

        describe " as normal user" do

          before(:each)do
            login_as(:user_normal)
          end

          it "should NOT let the User to edit a private space where the user has the role admin and render the edit action" do
            get :update ,:space => @invalid_attributes , :id => spaces(:private_admin).name
            response.should redirect_to(space_path(spaces(:private_admin).name))
          end

          it "should NOT let the User to try to edit a private space where the user has the role User" do
            get :update ,:space => @invalid_attributes , :id => spaces(:private_user).name
            assert_response 403
          end

          it "should NOT let the User to try to edit a private space where the user has the role invited " do
            get :update ,:space => @invalid_attributes , :id => spaces(:private_invited).name
            assert_response 403
          end

          it "should NOT let the User to try to edit a private space where the user has NO roles" do
            get :update ,:space => @invalid_attributes , :id => spaces(:private_no_roles).name
            assert_response 403
          end

          it "should NOT let the User to try to edit a public space where the user has no roles" do
            get :update ,:space => @valid_attributes , :id => spaces(:public).name
            assert_response 403
          end
        end
      end

      describe "if you are not logged in" do

        it "should NOT let the User to try to edit a private space " do
          get :update ,:space => @invalid_attributes , :id => spaces(:private_no_roles).name
          assert_response 401
        end

        it "should NOT let the User to try to edit a public space " do
          get :update ,:space => @invalid_attributes , :id => spaces(:public).name
          assert_response 401
        end
      end
    end
  end

##################################

  describe "responding to DELETE destroy" do

    describe " when you are logged in" do

      describe "as super admin" do

        before(:each)do
          login_as(:user_admin)
        end


        it "should let the User to delete a private space " do
          assert_difference 'Space.count', -1 do
            delete :destroy ,:id => spaces(:private_no_roles).name
          end
          response.should redirect_to(spaces_path)
        end

        it "should let the User to delete a public space " do
          assert_difference 'Space.count', -1 do
            delete :destroy ,:id => spaces(:public).name
          end
          response.should redirect_to(spaces_path)
        end
      end

      describe "as normal user" do

        before(:each) do
          login_as(:user_normal)
        end

        it "should let the User to delete a private space where the user has the role Admin " do
          assert_difference 'Space.count', -1 do
            delete :destroy ,:id => spaces(:private_admin).name
          end
          response.should redirect_to(spaces_path)
        end

        it "should NOT let the User to delete a private space where the user has the role User" do
          assert_no_difference 'Space.count' do
            delete :destroy ,:id => spaces(:private_user).name
          end
          assert_response 403
        end

        it "should NOT let the User to delete a private space where the user has the role invited " do
          assert_no_difference 'Space.count' do
            delete :destroy ,:id => spaces(:private_invited).name
          end
          assert_response 403
        end

        it "should NOT let the User to delete a private space where the user has no roles " do
          assert_no_difference 'Space.count' do
            delete :destroy ,:id => spaces(:private_no_roles).name
          end
          assert_response 403
        end

        it "should NOT let the User to delete a public space where the user has no roles " do
          assert_no_difference 'Space.count' do
            delete :destroy ,:id => spaces(:public).name
          end
          assert_response 403
        end
      end
    end

    describe " if you are not logged in" do

      it "should NOT let to delete a private space" do
        assert_no_difference 'Space.count' do
          delete :destroy ,:id => spaces(:private_no_roles).name
        end
        assert_response 401
      end

      it "should NOT let to delete a public space" do
        assert_no_difference 'Space.count' do
          delete :destroy ,:id => spaces(:public).name
        end
        assert_response 401
      end
    end
  end
=end

end
