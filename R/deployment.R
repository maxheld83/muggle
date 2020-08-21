#' @inherit shinycaas::az_webapp_config
#'
#' @examples
#' NULL
#' @details Wrapping with muggle defaults; use only inside muggle projects.
#'
#' @details # Authenticating Against GitHub Packages
#' Because muggle stores the docker images with the shiny runtimes on GitHub Packages, Azure must pull images from there, not the commonly used Docker Hub.
#'
#' Currently, GitHub Packages does not offer public images, even for public repositories ([#133](https://github.com/subugoe/muggle/issues/133)).
#' That means that Azure must be [authenticated](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages) to be able to download the runtime images.
#' This is the inverse of the the `azure login` GitHub Action, which authenticates the GitHub Actions runtime to talk to Azure.
#'
#' There are (only) two ways to do this, both suboptimal ([#132](https://github.com/subugoe/muggle/issues/132)):
#'
#' 1. You can authenticate Azure with a [personal access token (PAT)](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) and the corresponding **static GitHub username**.
#'    No matter who commits and triggered the deployment, always the same personal GitHub credentials (say, those of Jane Doe) will be used.
#'    To do this, the volunteering team member should create a PAT on GitHub, scope it minimally to only read packages, and paste that into the Azure web ui at portal.azure.com.
#'    A minimally scoped PAT may be reasonably safe, but the approach is still cumbersome and awkward.
#' 2. You can authenticate Azure towards GitHub Packages **with the `GITHUB_ACTOR` and `GITHUB_TOKEN` pair** [furnished](https://docs.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token) for GitHub Actions, from which the deployment takes place.
#'    The `GITHUB_ACTOR` environment variable will always be the GitHub username of whoever triggered the workflow run, and therefore, the deployment.
#'    The `GITHUB_TOKEN` is a PAT scoped to *only* that repo and will expire automatically after the workflow run is completed.
#'    To use this authentication, use the below defaults and expose the `GITHUB_TOKEN` to in your workflow `*.yaml` file.
#'
#'    ```yaml
#'    env:
#'      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
#'     ```
#'
#'    This is a more elegant, and arguably more secure solution, though the `GITHUB_TOKEN` still has more scope than just to read packages, if only for the repo in question.
#'    This form of authentication seems to work reliably, but may break future app (re)starts on Azure: Should Azure loose the docker cache of the image in question, it will not be able to `docker pull` the image again, because the `GITHUB_TOKEN` will have expired by then.
#'    Only a new workflow run can heal the app in this scenario.
#'    It remains to be seen how common this problem is.
#'
#' @export
az_webapp_config_muggle <- function(name = Sys.getenv("MUGGLE_PKG_NAME"),
                                    plan,
                                    resource_group,
                                    subscription,
                                    docker_registry_server_user = Sys.getenv("GITHUB_ACTOR"),
                                    docker_registry_server_password = Sys.getenv("GITHUB_TOKEN"),
                                    restart = FALSE) {
  shinycaas::az_webapp_config(
    name = name,
    deployment_container_image_name = gh_pkgs_image_url(),
    plan = plan,
    resource_group = resource_group,
    subscription = subscription,
    docker_registry_server_url = "https://docker.pkg.github.com",
    docker_registry_server_user = docker_registry_server_user,
    docker_registry_server_password = docker_registry_server_password,
    restart = restart
  )
}
