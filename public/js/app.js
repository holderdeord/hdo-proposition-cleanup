angular.module('SidebarController', ['ngHttp']);

function SidebarController ($scope, $http) {
  $scope.votes = [];
  $scope.links = [];

  $scope.fetchLinks = function(url) {
    $http({method: 'GET', url: url}).
      success(function(data, status, headers, config) {
        $scope.links = data;
      }).
      error(function(data, status, headers, config) {
        alert(data);
      });
  };

  $scope.fetchVotes = function(timestamp) {
    $http({method: 'GET', url: '/votes/' + timestamp}).
      success(function(data, status, headers, config) {
        $scope.votes = data;
      }).
      error(function(data, status, headers, config) {
        alert(data);
      });
  };

  $scope.directionFor = function(bool) {
    return {true: 'up', false: 'down'}[bool];
  };

  $scope.fetchLinks('/dates');
};


function DateController ($scope) {
  $scope.openDate = function() {
    var date = $scope.link;

    if (date.indexOf(":") != -1) {
      $scope.fetchVotes(date);
    } else {
      $scope.fetchLinks('/dates/' + date  + '/timestamps');
    }
  }
}

